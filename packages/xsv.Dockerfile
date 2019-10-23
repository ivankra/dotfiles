FROM debian:sid

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        equivs \
        git \
	cargo

RUN git clone git://github.com/BurntSushi/xsv /src
WORKDIR /src
RUN cargo build --release
RUN ls -l -R target
RUN { \
      echo "Section: dotfiles"; \
      echo "Priority: optional"; \
      echo "Standards-Version: 4.3.0"; \
      echo; \
      echo "Package: xsv"; \
      echo "Version: $(git describe --tags HEAD)"; \
      echo "Maintainer: none"; \
      echo "Architecture: amd64"; \
      echo "Description: A fast CSV command line toolkit written in Rust."; \
      echo "Copyright: UNLICENSE"; \
      echo "Readme: README.md"; \
      echo; \
      echo "Files: target/release/xsv /usr/local/bin/"; \
    } >control && \
    equivs-build control && \
    mkdir /dist && mv *.deb /dist/
