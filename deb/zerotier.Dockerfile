FROM debian:testing

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cargo \
        ca-certificates \
        clang \
        curl \
        devscripts \
        equivs \
        libssl-dev \
        lintian \
        git \
        pkg-config

RUN git clone --depth=10 https://github.com/zerotier/ZeroTierOne.git /src
WORKDIR /src
RUN git checkout "$(git describe --abbrev=0 --tags)"
RUN make -j && make -j debian
RUN mkdir -p /dist && mv /zerotier-one_*.deb /dist/
