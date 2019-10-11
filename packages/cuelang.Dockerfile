FROM debian:sid

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        equivs \
        git \
        golang

ENV GOPATH=/go
RUN go get -u -v cuelang.org/go/cmd/cue
WORKDIR /go/src/cuelang.org/go
RUN { \
      echo "Section: dotfiles"; \
      echo "Priority: optional"; \
      echo "Standards-Version: 4.3.0"; \
      echo; \
      echo "Package: cuelang"; \
      echo "Version: $(git describe --tags HEAD | cut -c 2-)"; \
      echo "Maintainer: none"; \
      echo "Architecture: amd64"; \
      echo "Description: The CUE Data Constraint Language"; \
      echo "Copyright: LICENSE"; \
      echo "Readme: README.md"; \
      echo; \
      echo "Files: /go/bin/cue /usr/local/bin/"; \
    } >control && \
    equivs-build control && \
    mkdir /dist && mv *.deb /dist/
