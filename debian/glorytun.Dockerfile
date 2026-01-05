FROM debian:buster

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        equivs \
        fakeroot \
        git \
        libsodium-dev

RUN git clone --recurse-submodules https://github.com/angt/glorytun /src
WORKDIR /src

RUN export VER="$(cd /src && git describe --tags HEAD | cut -c 2-)"; \
    make && \
    mkdir -p /pkg/usr/local/bin && \
    cp glorytun /pkg/usr/local/bin/ && \
    mkdir -p /pkg/DEBIAN && \
    { \
      echo "Package: glorytun"; \
      echo "Version: $VER"; \
      echo "Section: dotfiles"; \
      echo "Priority: optional"; \
      echo "Maintainer: none"; \
      echo "Architecture: amd64"; \
      echo "Description: Multipath UDP tunnel"; \
    } >/pkg/DEBIAN/control && \
    fakeroot dpkg-deb --build -Zxz -z9 /pkg "glorytun_${VER}_amd64.deb" && \
    mkdir /dist && mv *.deb /dist/
