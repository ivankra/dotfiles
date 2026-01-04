FROM debian:sid

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y \
      build-essential \
      ca-certificates \
      clangd \
      curl \
      emacs \
      fd-find \
      fzf \
      git \
      gopls \
      less \
      locales \
      neovim \
      nodejs \
      npm \
      python3 \
      python3-pip \
      ripgrep \
      rust-analyzer \
      sudo \
      tree-sitter-cli \
      unzip \
      wget && \
    echo "en_US.UTF-8 UTF-8" >/etc/locale.gen && \
    locale-gen

RUN npm install -g \
      pyright \
      typescript \
      typescript-language-server

ENV TERM=xterm-256color COLORTERM=truecolor

COPY persist-root.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/persist-root.sh
