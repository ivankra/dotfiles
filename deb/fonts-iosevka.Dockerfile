FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        equivs \
        git \
        nodejs \
        npm \
        ttfautohint

# Ref
# https://github.com/avivace/iosevka-docker/blob/master/Dockerfile
# https://gist.github.com/tasuten/0431d8af3e7b5ad5bc5347ce2d7045d7

ARG OTFCC_VER=0.10.4
ARG PREMAKE_VER=5.0.0-alpha15

# Dependency: premake5
RUN curl -sLo /tmp/premake5.tar.gz https://github.com/premake/premake-core/releases/download/v${PREMAKE_VER}/premake-${PREMAKE_VER}-linux.tar.gz
RUN cd /tmp && \
    tar xvf premake5.tar.gz && \
    mv premake5 /usr/local/bin/premake5 && \
    rm -f premake5.tar.gz

# Dependency: otfcc
WORKDIR /tmp
RUN curl -sLo /tmp/otfcc.tar.gz https://github.com/caryll/otfcc/archive/v${OTFCC_VER}.tar.gz
RUN cd /tmp && \
    tar xvf otfcc.tar.gz && \
    mv otfcc-${OTFCC_VER} otfcc && \
    cd /tmp/otfcc && \
    premake5 gmake && \
    cd /tmp/otfcc/build/gmake && \
    make config=release_x64 && \
    cd /tmp/otfcc/bin/release-x64 && \
    mv otfccbuild /usr/local/bin/otfccbuild && \
    mv otfccdump /usr/local/bin/otfccdump && \
    cd /tmp && \
    rm -rf otfcc/ otfcc.tar.gz

# Checkout latest tag and fetch npm deps
RUN git clone --depth=10 https://github.com/be5invis/Iosevka.git /src
WORKDIR /src
RUN git checkout "$(git describe --abbrev=0 --tags)"
RUN npm install

# Customize and build ttf fonts
RUN echo '\
[buildPlans.iosevka]\n\
family = "Iosevka"\n\
spacing = "fixed"\n\
serifs = "sans"\n\
no-ligation = true\n\
\n\
[buildPlans.iosevka.variants.design]\n\
asterisk = "hex-low"\n\
brace = "straight"\n\
l = "tailed-serifed"\n\
number-sign = "slanted"\n\
' >private-build-plans.toml
RUN npm run build -- ttf::iosevka

# Check build succeeed, artefacts were produced
RUN ls -l dist/iosevka/ttf/iosevka-regular.ttf

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
      for f in dist/iosevka/ttf/*.ttf; do \
        echo " $f /usr/share/fonts/truetype/iosevka"; \
      done; \
    } >control && \
    equivs-build control && \
    mkdir /dist && mv *.deb /dist/
