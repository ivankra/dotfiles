FROM debian:stable

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
	build-essential \
        ca-certificates \
	equivs \
        git

WORKDIR /build

RUN git clone https://github.com/google/jsonnet.git && \
    cd /build/jsonnet && \
    make -j && \
    strip jsonnet jsonnetfmt

COPY jsonnet.control /build/jsonnet/jsonnet.control

RUN cd /build/jsonnet/ && \
    export VERSION=$(./jsonnet --version | egrep -o '[0-9.]+$') && \
    envsubst <jsonnet.control >jsonnet.control.versioned && \
    equivs-build jsonnet.control.versioned && \
    mkdir output && \
    mv *.deb output/
