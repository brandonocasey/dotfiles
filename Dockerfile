FROM ubuntu:latest

RUN apt-get -y update && apt-get install -y curl && \
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply brandonocasey

CMD ["login"]
