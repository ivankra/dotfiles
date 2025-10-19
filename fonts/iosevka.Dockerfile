FROM debian:stable

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        equivs \
        git \
        nodejs \
        npm \
        ttfautohint && \
    rm -rf /var/lib/apt/lists/*

ARG REV=v33.3.3
RUN git clone --branch=$REV --depth=1 https://github.com/be5invis/Iosevka.git /src

WORKDIR /src

RUN npm install

COPY iosevka.toml ./private-build-plans.toml
RUN npm run build -- ttf::Iosevka

# Check that build succeeded, artefacts were produced
RUN ls -l ./dist/Iosevka/TTF/Iosevka-Regular.ttf

# Copy .ttf's to /dist/Iosevka/
RUN mkdir -p /dist/Iosevka && cp -R ./dist/Iosevka/TTF/*.ttf /dist/Iosevka

# Build debian package at /dist/fonts-iosevka_*.deb
RUN { \
      echo "Package: fonts-iosevka"; \
      echo "Version: $(git describe --tags HEAD | cut -c 2-)"; \
      echo "Section: dotfiles"; \
      echo "Priority: optional"; \
      echo "Maintainer: none"; \
      echo "Architecture: all"; \
      echo "Description: Iosevka - Slender typeface for code, from code"; \
      echo "Copyright: LICENSE.md"; \
      echo "Readme: README.md"; \
      echo; \
      echo -n "Files:"; \
      for f in ./dist/Iosevka/TTF/*.ttf; do \
        echo " $f /usr/share/fonts/truetype/iosevka"; \
      done; \
    } >control && \
    equivs-build control && \
    mv *.deb /dist
