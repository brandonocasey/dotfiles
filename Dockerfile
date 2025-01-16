FROM debian:stable-slim
ARG UNAME=brandonocasey
ARG UID=1000
ARG GID=1000
ENV RUNNING_IN_DOCKER=true
ENV PATH="${PATH}:./bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:/home/linuxbrew/.linuxbrew/bin"
ENV MANPATH="${MANPATH}:./man:/usr/share/man:/usr/local/man:/usr/local/share/man"

RUN apt-get -y update && \
  apt-get install -y curl sudo procps gcc binutils && \
  groupadd -g $GID -o $UNAME && \
  useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME && \
  usermod -aG sudo $UNAME && \
  echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER $UNAME
WORKDIR /home/$UNAME
RUN mkdir -p /home/$UNAME/.local/share
COPY . "/home/$UNAME/.local/share/chezmoi"
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- apply; \
   rm -rf ./bin/chezmoi && \
   rmdir --ignore-fail-on-non-empty ./bin && \
   sudo apt-get -y clean && \
   sudo rm -rf /home/$UNAME/.cache && \
   sudo rm -rf "$(/home/linuxbrew/.linuxbrew/bin/brew --cache)" && \
   sudo rm -rf /tmp/* && \
   /home/linuxbrew/.linuxbrew/bin/brew uninstall --ignore-dependencies gcc binutils

CMD ["/home/linuxbrew/.linuxbrew/bin/fish"]
