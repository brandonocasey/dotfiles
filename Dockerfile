FROM debian:stable-slim

ARG UNAME=brandonocasey
ARG UID=1000
ARG GID=1000

ENV RUNNING_IN_DOCKER=true
ENV PATH="${PATH}:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"
ENV MANPATH="${MANPATH}:./man:/usr/share/man:/usr/local/man:/usr/local/share/man"
# All persistent tool state lives under one dir (~/state) so a single host bind
# mount is the one place to keep/back up. The entrypoint seeds these from the
# chezmoi-managed config baked into the image so the empty mount doesn't shadow it.
ENV STATE_DIR="/home/${UNAME}/state"
ENV CLAUDE_CONFIG_DIR="/home/${UNAME}/state/claude"
ENV CODEX_HOME="/home/${UNAME}/state/codex"
# XDG_STATE_HOME holds genuinely-persistent state (nvim shada/undo, etc.).
# CONFIG/DATA/CACHE stay at defaults so chezmoi config and baked plugins/tools
# remain in the image and refresh on rebuild instead of freezing in the mount.
ENV XDG_STATE_HOME="/home/${UNAME}/state/xdg-state"
# mise toolchains live in ~/state (persisted) instead of the image: build uses
# them for nvim/LSP, then they're dropped from the image and reinstalled into
# the mount on first run by the entrypoint. Keeps the image smaller.
ENV MISE_DATA_DIR="/home/${UNAME}/state/mise"
# UTF-8 so TUIs (nvim, fzf) render correctly without a full locales package.
ENV LANG="C.UTF-8"
ENV CHROME_BIN="/usr/bin/google-chrome-stable"

# Install base system dependencies
RUN apt-get -y update && \
  apt-get install -y --no-install-recommends \
    curl \
    sudo \
    procps \
    gcc \
    binutils \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -g $GID -o $UNAME \
  && useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME \
  && usermod -aG sudo $UNAME \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Browser for the chrome-devtools MCP server: Google Chrome stable (the exact
# build the MCP targets). amd64-only, which matches this image. The .deb pulls
# in the shared libraries and fonts a bare slim image lacks.
RUN apt-get -y update && \
  apt-get install -y --no-install-recommends \
    gnupg \
    ca-certificates \
    fonts-liberation \
    openssh-server \
  && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
  && apt-get -y update \
  && apt-get install -y --no-install-recommends google-chrome-stable \
  && rm -rf /var/lib/apt/lists/*

# Docker CLI (+ compose/buildx plugins) so the container can drive a mounted
# host Docker socket (docker-out-of-Docker). Client only; no daemon runs here.
RUN apt-get -y update && \
  apt-get install -y --no-install-recommends gnupg && \
  install -m 0755 -d /etc/apt/keyrings && \
  curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
  chmod a+r /etc/apt/keyrings/docker.asc && \
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list && \
  apt-get -y update && \
  apt-get install -y --no-install-recommends \
    docker-ce-cli \
    docker-buildx-plugin \
    docker-compose-plugin \
  && rm -rf /var/lib/apt/lists/*

# Entrypoint registers the container-tuned chrome-devtools MCP server at runtime.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER $UNAME
WORKDIR /home/$UNAME

# Copy chezmoi scripts first for better layer caching
# This allows Docker to cache Homebrew installations when only dotfile configs change
COPY --chown=$UID:$GID home/.chezmoiscripts /home/$UNAME/.local/share/chezmoi/home/.chezmoiscripts
COPY --chown=$UID:$GID home/.chezmoi.toml.tmpl /home/$UNAME/.local/share/chezmoi/home/.chezmoi.toml.tmpl
COPY --chown=$UID:$GID home/.chezmoiignore /home/$UNAME/.local/share/chezmoi/home/.chezmoiignore
COPY --chown=$UID:$GID home/.chezmoiexternal.toml /home/$UNAME/.local/share/chezmoi/home/.chezmoiexternal.toml
COPY --chown=$UID:$GID .chezmoiroot /home/$UNAME/.local/share/chezmoi/.chezmoiroot

# Run pre-install scripts to install Homebrew packages (cached layer).
# Strip Homebrew's own git metadata (~130MB) in this same layer — it must be the
# layer that created it, or the bytes still ship. No `brew update` runs
# in-container (HOMEBREW_NO_AUTO_UPDATE is set), so brew still works without it.
RUN export CHEZMOI_SOURCE_DIR="/home/${UNAME}/.local/share/chezmoi" && \
    bash "/home/${UNAME}/.local/share/chezmoi/home/.chezmoiscripts/any-linux/run_onchange_before_pre-install.sh" && \
    rm -rf "$(/home/linuxbrew/.linuxbrew/bin/brew --repo)/.git"

# Copy remaining dotfiles
COPY --chown=$UID:$GID . /home/$UNAME/.local/share/chezmoi

# Run chezmoi apply and clean up
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- apply && \
   rm -rf ./bin/chezmoi && \
   rmdir --ignore-fail-on-non-empty ./bin && \
   sudo apt-get -y clean && \
   sudo rm -rf /home/$UNAME/.cache && \
   sudo rm -rf "$(/home/linuxbrew/.linuxbrew/bin/brew --cache)" && \
   sudo rm -rf /tmp/* && \
   sudo rm -rf "/home/$UNAME/state"

# Guard: fail the build if the Homebrew bundle or agent installs silently did
# nothing, instead of shipping a broken image. Checks brew tools and the
# native-installed agents (in ~/.local/bin).
RUN PATH="/home/${UNAME}/.local/bin:/home/linuxbrew/.linuxbrew/bin:${PATH}" sh -c '\
      for t in fish nvim mise fzf rg claude codex opencode; do \
        command -v "$t" >/dev/null || { echo "FATAL: $t missing after build" >&2; exit 1; }; \
      done'

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["fish"]
