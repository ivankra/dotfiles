FROM debian:stable

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
	build-essential \
        ca-certificates \
	equivs \
        git

RUN git clone https://github.com/google/jsonnet.git /src && \
    cd /src && make -j && strip jsonnet jsonnetfmt

COPY jsonnet.control.in /src/jsonnet.control.in

RUN cd /src && \
    export VERSION=$(git describe --tags HEAD | cut -c 2-) && \
    envsubst <jsonnet.control.in >jsonnet.control && \
    equivs-build jsonnet.control && \
    mkdir /dist && mv *.deb /dist/
