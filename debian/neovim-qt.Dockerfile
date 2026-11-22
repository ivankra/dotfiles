# neovim-qt from github.com/ivankra/neovim-qt branch dev, with Debian's packaging.
FROM debian:sid

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        devscripts \
        dpkg-dev \
        equivs \
        fakeroot \
        git

WORKDIR /build

ARG DEB_BUILD_OPTIONS="noddebs"
ENV DEB_BUILD_OPTIONS=${DEB_BUILD_OPTIONS}
ENV DEBFULLNAME="dotfiles" DEBEMAIL="dotfiles@localhost"

RUN apt-get source neovim-qt && \
    git clone --depth=1 -b dev https://github.com/ivankra/neovim-qt.git src

# Debian patches that no longer apply are already upstream (msgpack-c 7 fixes)
RUN cp -r neovim-qt-*/debian src/ && \
    cd src && \
    for p in $(cat debian/patches/series); do \
        if git apply --check "debian/patches/$p"; then echo "$p"; else echo "Dropping $p" >&2; fi; \
    done > series && \
    mv series debian/patches/series && \
    upstream=$(dpkg-parsechangelog -SVersion | sed 's/-[^-]*$//') && \
    dch -v "$upstream+git$(git log -1 --format=%cd.%h --date=format:%Y%m%d)-1" \
        "Build from github.com/ivankra/neovim-qt branch dev." && \
    dch -r "" && \
    mk-build-deps --install --remove \
        --tool "apt-get -y --no-install-recommends" debian/control && \
    dpkg-buildpackage -us -uc -b

RUN mkdir /dist && mv /build/*.deb /dist/
