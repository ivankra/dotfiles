FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        equivs \
        git \
        pyqt5-dev-tools \
        python3-lxml \
        python3-pyqt5 \
        python3-setuptools

RUN git clone https://github.com/tzutalin/labelImg /pkg/usr/local/share/labelimg
WORKDIR /pkg/usr/local/share/labelimg
RUN make qt5py3

WORKDIR /tmp
RUN export VER="$(cd /pkg/usr/local/share/labelimg && git describe --tags HEAD | cut -c 2-)" && \
    rm -rf /pkg/usr/local/share/labelimg/.git && \
    \
    mkdir -p /pkg/usr/local/bin && \
    { \
      echo "#!/bin/bash"; \
      echo "set -ex"; \
      echo 'firejail --caps.drop=all --net=none python3 /usr/local/share/labelimg/labelImg.py "$@"'; \
    } >/pkg/usr/local/bin/labelImg && \
    chmod a+rx /pkg/usr/local/bin/labelImg && \
    \
    mkdir -p /pkg/DEBIAN && \
    { \
      echo "Package: labelimg"; \
      echo "Version: $VER"; \
      echo "Section: dotfiles"; \
      echo "Priority: optional"; \
      echo "Maintainer: none"; \
      echo "Architecture: all"; \
      echo "Description: Graphical image annotation tool"; \
      echo "Depends: python3-lxml, python3-pyqt5, python3-setuptools, firejail"; \
    } >/pkg/DEBIAN/control && \
    fakeroot dpkg-deb --build -Zxz -z9 -Sextreme /pkg "labelimg_${VER}_all.deb" && \
    mkdir /dist && mv *.deb /dist/
