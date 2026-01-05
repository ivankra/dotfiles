FROM debian:buster

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cdbs \
        equivs \
        fakeroot \
        git \
        libev-dev \
        libpcap-dev \
        libsodium-dev \
        pkg-config \
        ruby-ronn

RUN git clone https://github.com/zehome/MLVPN /src
WORKDIR /src

RUN dpkg-buildpackage -us -uc -rfakeroot && \
    mkdir /dist && mv ../mlvpn_*_amd64.deb /dist/
