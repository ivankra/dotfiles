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
        mypy \
        nano \
        net-tools \
        netcat-openbsd \
        nftables \
        ninja-build \
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
        byobu \
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

ENV LC_ALL=en_US.UTF-8 \
    SHELL=/bin/bash \
    NVM_DIR=/usr/local/nvm \
    UV_INSTALL_DIR=/usr/local/bin \
    UV_TOOL_DIR=/usr/local/share/uv \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    PATH=/root/.local/bin:/usr/local/node/bin:/usr/local/go/bin:$PATH

RUN rustup toolchain install stable && rustup default stable && \
    rustup component add rust-analyzer

RUN GOLANG_ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    VER=$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n1 | sed 's/go//') && \
    curl -fL -o /tmp/go.tar.gz https://go.dev/dl/go${VER}.linux-${GOLANG_ARCH}.tar.gz && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm -f /tmp/go.tar.gz

RUN mkdir -p "$NVM_DIR" && \
    curl -o /tmp/nvm-install.sh https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh && \
    echo "4b7412c49960c7d31e8df72da90c1fb5b8cccb419ac99537b737028d497aba4f  /tmp/nvm-install.sh" | sha256sum -c && \
    bash /tmp/nvm-install.sh && rm -f /tmp/nvm-install.sh && \
    bash -c 'source /usr/local/nvm/nvm.sh && nvm install node' && \
    ln -s /usr/local/nvm/versions/node/*/ /usr/local/node

RUN npm install -g \
        @biomejs/biome \
        esbuild \
        pnpm \
        prettier \
        rolldown \
        serve \
        tsx \
        typescript

RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    uv tool install ty && \
    uv tool install pyright && \
    uv tool install ruff && \
    uv tool install black
