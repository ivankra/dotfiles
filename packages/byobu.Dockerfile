FROM debian:buster

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        autoconf \
        build-essential \
        bzr \
        ca-certificates \
        fakeroot

RUN echo "deb-src http://deb.debian.org/debian buster main" >>/etc/apt/sources.list
RUN apt-get update && \
    apt-get build-dep -y byobu

WORKDIR /src
RUN bzr branch lp:byobu

WORKDIR /src/byobu
RUN ./autogen.sh && ./configure && make && make install DESTDIR=/pkg

RUN mkdir -p /pkg/DEBIAN && \
    export VER="$(bzr log | sed -Ene 's/^ *opening ([0-9.]+)/\1/p' | head -1).$(date +%Y%m%d)" && \
    { \
      echo "Package: byobu"; \
      echo "Version: $VER"; \
      echo "Section: dotfiles"; \
      echo "Depends: python, tmux, gawk"; \
      echo "Priority: optional"; \
      echo "Maintainer: none"; \
      echo "Architecture: amd64"; \
      echo "Description: byobu"; \
    } >/pkg/DEBIAN/control && \
    fakeroot dpkg-deb --build /pkg "byobu_${VER}_amd64.deb" && \
    mkdir /dist && mv *.deb /dist/
