FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        devscripts \
        equivs \
        libssl-dev \
        git

RUN git clone https://github.com/Wind4/vlmcsd.git /src
WORKDIR /src
RUN git checkout "$(git describe --abbrev=0 --tags)"
RUN git submodule init
RUN git submodule update
RUN gmake -j
RUN debuild --no-lintian -I -i -us -uc -nc -b
RUN mkdir -p /dist && mv /vlmcsd_*.deb /dist
