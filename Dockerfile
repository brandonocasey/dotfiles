FROM debian:stable-slim
ARG UNAME=brandonocasey
ARG UID=1000
ARG GID=1000
RUN apt-get -y update && apt-get install -y curl sudo

RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME
RUN usermod -aG sudo $UNAME
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER $UNAME
WORKDIR /home/$UNAME

RUN curl -fsLS get.chezmoi.io -o chezmoi-install.sh && \
  /bin/bash chezmoi-install.sh -b /tmp/chezmoi-bin && \
  /tmp/chezmoi-bin/chezmoi init --apply brandonocasey && \
  rm -rf /tmp/chezmoi-bin


CMD ["login"]
