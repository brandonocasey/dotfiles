FROM debian:stable-slim
ARG UNAME=brandonocasey
ARG UID=1000
ARG GID=1000

RUN apt-get -y update && \
  apt-get install -y curl sudo git && \
  groupadd -g $GID -o $UNAME && \
  useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME && \
  usermod -aG sudo $UNAME && \
  echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
  mkdir -p /home/$UNAME/.local/share && \
  chown -R $UID:$PID /home/$UNAME
  
USER $UNAME
WORKDIR /home/$UNAME

COPY . "/home/$UNAME/.local/share/chezmoi"
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- apply; \
   rm -rf ./bin/chezmoi && \
   rmdir --ignore-fail-on-non-empty ./bin && \
   sudo apt-get -y clean && \
   rm -rf /home/$UNAME/.cache && \
   sudo rm -rf "$(/home/linuxbrew/.linuxbrew/brew --cache)" && \ 
   brew rm gcc

CMD ["/home/linuxbrew/.linuxbrew/bin/fish"]
