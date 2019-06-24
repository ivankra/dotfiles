FROM debian:stable

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
	build-essential \
        ca-certificates \
	equivs \
        git

RUN git clone --depth=1 https://github.com/google/jsonnet.git /src && \
    cd /src && make -j && strip jsonnet jsonnetfmt

COPY jsonnet.control.in /src/jsonnet.control.in

RUN cd /src && \
    export VERSION=$(./jsonnet --version | egrep -o '[0-9.]+$') && \
    envsubst <jsonnet.control.in >jsonnet.control && \
    equivs-build jsonnet.control && \
    mkdir /dist && mv *.deb /dist/
