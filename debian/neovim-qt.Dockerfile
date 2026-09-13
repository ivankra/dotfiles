# neovim-qt from Debian's packaging, updated to the latest upstream release.
FROM debian:sid

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        devscripts \
        dpkg-dev \
        equivs \
        fakeroot \
        libwww-perl \
        liblwp-protocol-https-perl

WORKDIR /build

ARG DEB_BUILD_OPTIONS="noddebs"
ENV DEB_BUILD_OPTIONS=${DEB_BUILD_OPTIONS}
ENV DEBFULLNAME="dotfiles" DEBEMAIL="dotfiles@localhost"

RUN apt-get source neovim-qt && \
    cd neovim-qt-*/ && \
    uscan --report --dehs | sed -n 's:.*<upstream-version>\(.*\)</upstream-version>.*:\1:p' > /build/VERSION && \
    test -s /build/VERSION && \
    uscan --download --rename && \
    uupdate ../neovim-qt_$(cat /build/VERSION).orig.tar.gz

# 0.2.20 switched to Qt6 and requires msgpack-c >= 6
RUN ver=$(cat VERSION) && \
    cd neovim-qt-$ver && \
    sed -i \
        -e 's/libmsgpack-dev (>= 1.4.0-2)/libmsgpack-c-dev (>= 6.0.0)/' \
        -e 's/libqt5svg5-dev/qt6-svg-dev/' \
        -e 's/qtbase5-dev/qt6-base-dev/' \
        -e 's/Qt5 GUI/Qt6 GUI/' \
        debian/control && \
    dch -a "Build against Qt6 and msgpack-c as required by upstream." && \
    for c in 9ea62b0 80971ef; do \
        curl -fsSL -o debian/patches/msgpack-c-7-$c.patch \
            https://github.com/equalsraf/neovim-qt/commit/$c.patch || exit 1; \
    done && \
    if patch -p1 --dry-run -N -s < debian/patches/msgpack-c-7-9ea62b0.patch >/dev/null; then \
        printf '%s\n' msgpack-c-7-9ea62b0.patch msgpack-c-7-80971ef.patch >> debian/patches/series && \
        dch -a "Backport upstream 9ea62b0, 80971ef to allow building with msgpack-c 7."; \
    else \
        rm debian/patches/msgpack-c-7-*.patch; \
    fi && \
    dch -r "" && \
    mk-build-deps --install --remove \
        --tool "apt-get -y --no-install-recommends" debian/control && \
    dpkg-buildpackage -us -uc -b

RUN mkdir /dist && mv /build/*.deb /dist/
