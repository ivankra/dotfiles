FROM debian:stable

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        fakeroot \
        gettext \
        libadwaita-1-dev \
        libgtk-4-dev \
        libgtk4-layer-shell-dev \
        libxml2-utils \
        pkg-config \
        tar \
        wget \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

# https://ziglang.org/download/
ARG ZIG_VER=0.15.2
RUN export ZIG_ARCH=$(uname -m | sed 's/ppc64le/powerpc64le/; s/i686/x86/; s/armv7l/arm/'); \
    cd /opt && \
    wget -O zig.tar.xz "https://ziglang.org/download/$ZIG_VER/zig-${ZIG_ARCH}-linux-$ZIG_VER.tar.xz" && \
    tar vxf zig.tar.xz && \
    rm -f zig.tar.xz && \
    ln -s /opt/zig-*/zig /usr/bin/zig

# https://ghostty.org/docs/install/build
ARG GHOSTTY_REF=tip
RUN curl -fL -o /tmp/ghostty-source.tar.gz "https://github.com/ghostty-org/ghostty/releases/download/${GHOSTTY_REF}/ghostty-source.tar.gz" && \
    mkdir -p /src && \
    tar -xf /tmp/ghostty-source.tar.gz -C /src --strip-components=1 && \
    rm -f /tmp/ghostty-source.tar.gz

WORKDIR /src

RUN zig build -p /pkg/usr/local -Doptimize=ReleaseFast

RUN set -eux; \
    DEB_ARCH="$(dpkg --print-architecture)"; \
    VER="$(date +%Y%m%d)"; \
    mkdir -p /pkg/DEBIAN /dist; \
    { \
      echo "Package: ghostty"; \
      echo "Version: $VER"; \
      echo "Section: x11"; \
      echo "Priority: optional"; \
      echo "Maintainer: none"; \
      echo "Architecture: $DEB_ARCH"; \
      echo "Depends: libgtk-4-1, libadwaita-1-0, libgtk4-layer-shell0"; \
      echo "Homepage: https://ghostty.org/"; \
      echo "Description: Ghostty terminal emulator"; \
    } >/pkg/DEBIAN/control; \
    fakeroot dpkg-deb --build /pkg "/dist/ghostty_${VER}_${DEB_ARCH}.deb"
