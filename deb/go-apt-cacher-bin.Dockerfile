FROM debian:sid

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        equivs \
        fakeroot \
        git \
        golang

ENV GOPATH=/go
RUN go get -v -u github.com/cybozu-go/aptutil/...
WORKDIR /go

RUN export VER="$(cd /go/src/github.com/cybozu-go/aptutil && git describe --tags HEAD | cut -c 2-)"; \
    mkdir -p /pkg/usr/local/bin && \
    cp /go/bin/go-apt-cacher /pkg/usr/local/bin/ && \
    cp /go/bin/go-apt-mirror /pkg/usr/local/bin/ && \
    mkdir -p /pkg/DEBIAN && \
    { \
      echo "Package: go-apt-cacher-bin"; \
      echo "Version: $VER"; \
      echo "Section: dotfiles"; \
      echo "Priority: optional"; \
      echo "Maintainer: none"; \
      echo "Architecture: amd64"; \
      echo "Description: Caching reverse proxy built specially for Debian (APT) repositories (binaries)"; \
    } >/pkg/DEBIAN/control && \
    fakeroot dpkg-deb --build -Zxz -z9 -Sextreme /pkg "go-apt-cacher-bin_${VER}_amd64.deb" && \
    mkdir /dist && mv *.deb /dist/

