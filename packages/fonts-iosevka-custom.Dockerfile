FROM debian:bullseye

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

# Dependency: premake5
# https://gist.github.com/tasuten/0431d8af3e7b5ad5bc5347ce2d7045d7
WORKDIR /tmp
RUN curl -sLo premake5.tar.gz https://github.com/premake/premake-core/releases/download/v5.0.0-alpha14/premake-5.0.0-alpha14-linux.tar.gz
RUN tar xvf premake5.tar.gz && mv premake5 /usr/local/bin/premake5 && rm premake5.tar.gz

# Dependency: otfcc
WORKDIR /tmp
RUN curl -sLo otfcc.tar.gz https://github.com/caryll/otfcc/archive/v0.9.6.tar.gz
RUN tar xvf otfcc.tar.gz && mv otfcc-0.9.6 otfcc
WORKDIR /tmp/otfcc
RUN premake5 gmake && cd build/gmake && make config=release_x64
WORKDIR /tmp/otfcc/bin/release-x64
RUN mv otfccbuild /usr/local/bin/otfccbuild
RUN mv otfccdump /usr/local/bin/otfccdump
WORKDIR /tmp
RUN rm -rf otfcc/ otfcc.tar.gz

# Checkout latest tag and fetch npm deps
RUN git clone https://github.com/be5invis/Iosevka.git /tmp/iosevka
WORKDIR /tmp/iosevka
RUN git checkout "$(git describe --abbrev=0 --tags)"
RUN npm install

# Build default font
#RUN npm run build -- contents::iosevka
#RUN ls -l dist/iosevka/ttf/iosevka-regular.ttf

# Build custom font
#RUN sed -e '/family = "Iosevka"/a design = ["term", "ss04"]' -i build-plans.toml
RUN { \
      echo '[buildPlans.iosevka-custom]'; \
      echo 'family = "Iosevka Custom"'; \
      echo 'design = ["sp-fixed", "cv08", "cv36", "cv45", "cv61"]'; \
    } >private-build-plans.toml
RUN npm run build -- contents::iosevka-custom
RUN ls -l dist/iosevka-custom/ttf/iosevka-custom-regular.ttf

RUN { \
      echo "Package: fonts-iosevka-custom"; \
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
      for f in dist/iosevka-custom/ttf/*.ttf; do \
        echo " $f /usr/share/fonts/truetype/iosevka-custom"; \
      done; \
    } >control && \
    equivs-build control && \
    mkdir /dist && mv *.deb /dist/
