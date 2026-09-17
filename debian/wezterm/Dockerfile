# wezterm built from upstream git, packaged with upstream's ci/deploy.sh
FROM debian:stable

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bsdutils \
        build-essential \
        ca-certificates \
        cmake \
        dpkg-dev \
        fakeroot \
        git \
        libegl1-mesa-dev \
        libfontconfig1-dev \
        libssl-dev \
        libwayland-dev \
        libx11-xcb-dev \
        libxcb-ewmh-dev \
        libxcb-icccm4-dev \
        libxcb-image0-dev \
        libxcb-keysyms1-dev \
        libxcb-randr0-dev \
        libxcb-render0-dev \
        libxcb-util-dev \
        libxcb-xkb-dev \
        libxkbcommon-dev \
        libxkbcommon-x11-dev \
        lsb-release \
        ncurses-bin \
        pkg-config \
        python3 \
        rustup \
        xdg-utils \
        xorg-dev

RUN rustup set profile minimal && rustup default stable

RUN git clone --depth=1 --recurse-submodules --shallow-submodules \
        https://github.com/wezterm/wezterm.git /src

WORKDIR /src

COPY *.patch /tmp/
RUN git apply /tmp/*.patch

RUN cargo build --release -p wezterm-gui -p wezterm -p wezterm-mux-server -p strip-ansi-escapes

RUN bash ci/deploy.sh

# Rename deploy.sh's wezterm-<ver>.Debian13.arm64.deb to wezterm_<ver>_arm64.deb
RUN mkdir /dist && dpkg-name -s /dist wezterm-*.deb
