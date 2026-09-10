FROM debian:stable

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        equivs \
        jq \
        git \
        nodejs \
        npm \
        ttfautohint \
        python3 \
        python3-fontforge \
        fontforge

WORKDIR /src/iosevka

# Shallow clone latest release tag.
RUN REV=$(curl -fsSL https://api.github.com/repos/be5invis/Iosevka/releases/latest | jq -r .tag_name) && \
    git clone --branch="$REV" --depth=1 https://github.com/be5invis/Iosevka.git .

RUN npm install

COPY iosevka.toml ./private-build-plans.toml
RUN npm run build -- ttf::Iosevka
RUN mkdir -p /dist/iosevka && cp -R ./dist/Iosevka/TTF/Iosevka*.ttf /dist/iosevka/

# Iosevka NFM variant for nvim
RUN sed -i 's/\.Iosevka/.IosevkaNerdFontMono/' ./private-build-plans.toml && \
    sed -i 's/family = .*/family = "Iosevka NFM"/' ./private-build-plans.toml && \
    sed -i 's/spacing = .*/spacing = "fixed"/' ./private-build-plans.toml && \
    rm -rf ./dist && \
    npm run build -- ttf::IosevkaNerdFontMono

# Patch using nerd fonts font-patcher from its latest release tag.
RUN REV=$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | jq -r .tag_name) && \
    git clone --filter=blob:none --sparse --branch="$REV" --depth=1 https://github.com/ryanoasis/nerd-fonts.git /src/nf && \
    cd /src/nf && \
    git sparse-checkout init --no-cone && \
    git sparse-checkout set --skip-checks '/*' '!/patched-fonts' '!/src/unpatched-fonts'

RUN export PYTHONIOENCODING=utf-8; \
    for font in /src/iosevka/dist/IosevkaNerdFontMono/TTF/*.ttf; do \
      rm -rf /tmp/nf && \
      mkdir -p /tmp/nf && \
      fontforge -script /src/nf/font-patcher \
        --complete \
        --careful \
        --outputdir /tmp/nf \
        --makegroups 0 \
        "$font" && \
      mv /tmp/nf/*.ttf /dist/iosevka/ || exit 1; \
    done

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
      for f in /dist/iosevka/*.ttf; do \
        echo " $f /usr/share/fonts/truetype/iosevka"; \
      done; \
    } >control && \
    equivs-build control && \
    mv *.deb /dist
