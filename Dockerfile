FROM debian:stable-slim
ARG UNAME=brandonocasey
ARG UID=1000
ARG GID=1000
ARG BRANCH=main
RUN apt-get -y update && apt-get install -y curl sudo

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME
RUN usermod -aG sudo $UNAME
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER $UNAME
WORKDIR /home/$UNAME

RUN mkdir -p /home/$UNAME/.local/share

COPY . "/home/$UNAME/.local/share/chezmoi"
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- apply; rm -rf ./bin/chezmoi && rmdir bin
RUN sudo apt-get -y clean
RUN rm -rf /home/$UNAME/.cache

CMD ["/home/linuxbrew/.linuxbrew/bin/fish"]
