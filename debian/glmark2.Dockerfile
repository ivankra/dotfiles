FROM debian:sid

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        equivs \
        git \
        libjpeg-dev \
        libpng-dev \
        libx11-dev \
        pkg-config \
        python

RUN git clone https://github.com/glmark2/glmark2 /src
WORKDIR /src
RUN ./waf configure --with-flavors=x11-gl
RUN ./waf
RUN ./waf install

RUN mkdir -p pkg/DEBIAN pkg/usr/local/bin pkg/usr/local/share && \
    export VER=$(date +%Y%m%d).$(git show-ref --hash=8 HEAD) && \
    { \
      echo "Package: glmark2"; \
      echo "Version: $VER"; \
      echo "Section: dotfiles"; \
      echo "Priority: optional"; \
      echo "Maintainer: none"; \
      echo "Architecture: amd64"; \
      echo "Description: glmark2"; \
    } >pkg/DEBIAN/control && \
    cp /usr/local/bin/glmark2 pkg/usr/local/bin && \
    cp -a /usr/local/share/glmark2 pkg/usr/local/share/ && \
    fakeroot dpkg-deb --build pkg "glmark2_${VER}_amd64.deb" && \
    mkdir /dist && mv *.deb /dist/
