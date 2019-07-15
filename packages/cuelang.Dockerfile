FROM debian:sid

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        equivs \
        git \
        golang-1.12

ENV GOPATH=/go
RUN /usr/lib/go-1.12/bin/go get -u -v cuelang.org/go/cmd/cue

COPY cuelang.control.in /cuelang.control.in

RUN cd /go/src/cuelang.org/go && \
    export VERSION=$(git describe --tags HEAD | cut -c 2-) && \
    envsubst </cuelang.control.in >cuelang.control && \
    strip /go/bin/cue && \
    equivs-build cuelang.control && \
    mkdir /dist && mv *.deb /dist/
