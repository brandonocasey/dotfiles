FROM debian:stable-slim

ARG UNAME=brandonocasey
ARG UID=1000
ARG GID=1000

ENV RUNNING_IN_DOCKER=true
ENV PATH="${PATH}:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"
ENV MANPATH="${MANPATH}:./man:/usr/share/man:/usr/local/man:/usr/local/share/man"

# Install base system dependencies
RUN apt-get -y update && \
  apt-get install -y --no-install-recommends \
    curl \
    sudo \
    procps \
    gcc \
    binutils \
    unzip \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -g $GID -o $UNAME \
  && useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME \
  && usermod -aG sudo $UNAME \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER $UNAME
WORKDIR /home/$UNAME

# Copy chezmoi scripts first for better layer caching
# This allows Docker to cache Homebrew installations when only dotfile configs change
COPY --chown=$UID:$GID home/.chezmoiscripts /home/$UNAME/.local/share/chezmoi/home/.chezmoiscripts
COPY --chown=$UID:$GID home/.chezmoi.toml.tmpl /home/$UNAME/.local/share/chezmoi/home/.chezmoi.toml.tmpl
COPY --chown=$UID:$GID home/.chezmoiignore /home/$UNAME/.local/share/chezmoi/home/.chezmoiignore
COPY --chown=$UID:$GID home/.chezmoiexternal.toml /home/$UNAME/.local/share/chezmoi/home/.chezmoiexternal.toml
COPY --chown=$UID:$GID .chezmoiroot /home/$UNAME/.local/share/chezmoi/.chezmoiroot

# Run pre-install scripts to install Homebrew packages (cached layer)
RUN export CHEZMOI_SOURCE_DIR="/home/${UNAME}/.local/share/chezmoi" && \
    bash "/home/${UNAME}/.local/share/chezmoi/home/.chezmoiscripts/any-linux/run_onchange_before_pre-install.sh"

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
   /home/linuxbrew/.linuxbrew/bin/brew uninstall --ignore-dependencies gcc binutils || true

CMD ["fish"]
