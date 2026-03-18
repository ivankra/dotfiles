# Base container with common tools for agent sandboxes

FROM debian:sid

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get dist-upgrade -y

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        aggregate \
        apt-transport-https \
        autoconf \
        automake \
        bash \
        bash-completion \
        bat \
        bc \
        bind9-dnsutils \
        bind9-host \
        bison \
        bsdextrautils \
        bsdmainutils \
        bsdutils \
        build-essential \
        busybox \
        bzip2 \
        ca-certificates \
        cloc \
        cmake \
        curl \
        delta \
        diffutils \
        dnsutils \
        entr \
        fd-find \
        ffmpeg \
        file \
        findutils \
        flex \
        fzf \
        gdb \
        gettext \
        gh \
        ghostscript \
        git \
        gnupg2 \
        golang \
        gperf \
        graphviz \
        gzip \
        httpie \
        imagemagick \
        inotify-tools \
        iproute2 \
        ipset \
        iptables \
        jq \
        less \
        libffi-dev \
        libicu-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        locales \
        lsb-release \
        lsof \
        luajit \
        make \
        man-db \
        manpages \
        manpages-dev \
        mbuffer \
        miller \
        moreutils \
        nano \
        net-tools \
        netcat-openbsd \
        nftables \
        ninja-build \
        nodejs \
        npm \
        openjdk-25-jdk-headless \
        openssl \
        p7zip-full \
        # pandoc \ # broken in sid 2026-03-27: unsatisfiable pandoc-data dep
        parallel \
        patch \
        pdftk-java \
        perl \
        pkg-config \
        poppler-utils \
        procps \
        psmisc \
        pv \
        python-is-python3 \
        python3 \
        python3-csvkit \
        python3-matplotlib \
        python3-mypy \
        python3-pandas \
        python3-pip \
        python3-pytest \
        python3-scipy \
        python3-venv \
        python3-yaml \
        ripgrep \
        rsync \
        ruby \
        rustup \
        screen \
        shellcheck \
        socat \
        sqlite3 \
        ssh \
        sshfs \
        strace \
        sudo \
        tar \
        tcpdump \
        tesseract-ocr \
        time \
        tmux \
        tokei \
        traceroute \
        tree \
        unzip \
        vim \
        wget \
        whois \
        xxd \
        xz-utils \
        yq \
        zip \
        zlib1g-dev \
        zsh \
        zstd && \
    echo "en_US.UTF-8 UTF-8" >/etc/locale.gen && \
    locale-gen

RUN rustup toolchain install stable && rustup default stable && \
    rustup component add rust-analyzer

ENV LC_ALL=en_US.UTF-8
ENV PATH=/root/.local/bin:$PATH
ENV SHELL=/bin/bash

RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    uv tool install ty && \
    uv tool install pyright && \
    uv tool install ruff && \
    uv tool install black
