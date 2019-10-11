FROM debian:sid

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        equivs \
        git \
        golang

ENV GOPATH=/go
RUN git clone https://github.com/aptly-dev/aptly /src
WORKDIR /src
RUN make modules install

RUN { \
      echo "Section: dotfiles"; \
      echo "Priority: optional"; \
      echo "Standards-Version: 4.3.0"; \
      echo; \
      echo "Package: aptly"; \
      echo "Version: $(git describe --tags HEAD | cut -c 2-)"; \
      echo "Maintainer: none"; \
      echo "Architecture: amd64"; \
      echo "Description: aptly"; \
      echo "Copyright: LICENSE"; \
      echo "Readme: README.rst"; \
      echo; \
      echo "Files: /go/bin/aptly /usr/local/bin/"; \
    } >control && \
    equivs-build control && \
    mkdir /dist && mv *.deb /dist/
