FROM debian:buster

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        equivs \
        fakeroot \
        git

RUN git clone https://github.com/jedisct1/dsvpn /src
WORKDIR /src

RUN export VER="$(cd /src && git describe --tags HEAD)"; \
    make && \
    mkdir -p /pkg/usr/local/bin && \
    cp dsvpn /pkg/usr/local/bin/ && \
    mkdir -p /pkg/DEBIAN && \
    { \
      echo "Package: dsvpn"; \
      echo "Version: $VER"; \
      echo "Section: dotfiles"; \
      echo "Priority: optional"; \
      echo "Maintainer: none"; \
      echo "Architecture: amd64"; \
      echo "Description: Dead Simple VPN"; \
    } >/pkg/DEBIAN/control && \
    fakeroot dpkg-deb --build -Zxz -z9 /pkg "dsvpn_${VER}_amd64.deb" && \
    mkdir /dist && mv *.deb /dist/
