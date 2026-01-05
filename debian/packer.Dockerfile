FROM debian:testing

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        equivs \
        fakeroot \
        git \
        golang

ENV GOPATH=/go
RUN git clone https://github.com/hashicorp/packer.git /src
WORKDIR /src

#RUN git checkout $(git tag -l 'v*' | sort -V | tail -1)
#RUN make release

RUN make dev

RUN export VER="$(/go/bin/packer version | sed -e 's/Packer v//; s/ /-/; s/[()]//g')" && \
    mkdir -p /pkg/usr/local/bin && \
    cp -a /go/bin/packer /pkg/usr/local/bin/packer && \
    mkdir -p /pkg/DEBIAN && \
    { \
      echo "Section: dotfiles"; \
      echo "Priority: optional"; \
      echo "Package: packer"; \
      echo "Version: $VER"; \
      echo "Maintainer: none"; \
      echo "Architecture: amd64"; \
      echo "Description: packer"; \
    } >/pkg/DEBIAN/control && \
    fakeroot dpkg-deb --build /pkg "packer_${VER}_amd64.deb" && \
    mkdir /dist && mv *.deb /dist/
