FROM debian:stable-slim
ARG UNAME=brandonocasey
ARG UID=1000
ARG GID=1000
ENV RUNNING_IN_DOCKER=true
RUN apt-get -y update && \
  apt-get install -y curl sudo git && \
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
   /home/linuxbrew/.linuxbrew/bin/brew uninstall --ignore-dependencies gcc

CMD ["/home/linuxbrew/.linuxbrew/bin/fish"]
