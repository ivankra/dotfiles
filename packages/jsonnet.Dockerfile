FROM debian:sid

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        equivs \
        git

RUN git clone https://github.com/google/jsonnet.git /src
WORKDIR /src
RUN make -j && strip jsonnet jsonnetfmt
RUN { \
      echo "Section: dotfiles"; \
      echo "Priority: optional"; \
      echo "Standards-Version: 4.3.0"; \
      echo; \
      echo "Package: jsonnet"; \
      echo "Version: $(git describe --tags HEAD | cut -c 2-)"; \
      echo "Maintainer: none"; \
      echo "Architecture: amd64"; \
      echo "Description: Jsonnet data templating language"; \
      echo "Copyright: LICENSE"; \
      echo "Readme: README.md"; \
      echo; \
      echo "Files: jsonnet /usr/local/bin/"; \
      echo " jsonnetfmt /usr/local/bin/"; \
    } >control && \
    equivs-build control && \
    mkdir /dist && mv *.deb /dist/
