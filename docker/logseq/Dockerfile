FROM debian:sid

RUN export DEBIAN_FRONTEND=noninteractive && \
    sed -i 's/ main/ main contrib non-free/g' /etc/apt/sources.list.d/debian.sources && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        locales \
        python3 \
        unzip \
        wget \
        zstd \
        # Input method support via fcitx. Needs --hostdbus to talk to fcitx5 on host. \
        fcitx5 \
        fcitx5-chinese-addons \
        fcitx5-frontend-gtk2 \
        fcitx5-frontend-gtk3 \
        fcitx5-frontend-gtk4 \
        fcitx5-frontend-qt5 \
        fcitx5-frontend-qt6 \
        fcitx5-material-color \
        # Fonts, some from non-free. noto-color-emoji for country flags. \
        fonts-moe-standard-kai \
        fonts-moe-standard-song \
        fonts-noto \
        fonts-noto-cjk \
        fonts-noto-color-emoji \
        fonts-opensymbol \
        fonts-roboto \
        fonts-wqy-microhei \
        fonts-wqy-zenhei \
        # Various runtime dependencies \
        libasound2t64 \
        libdbus-1-3 \
        libegl1 \
        libfontconfig1 \
        libfreetype6 \
        libgl1 \
        libglib2.0-0 \
        libnss3 \
        libqt6gui6 \
        libxcb-cursor0 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-randr0 \
        libxcb-render-util0 \
        libxcb-shape0 \
        libxcb-xinerama0 \
        libxcb-xkb1 \
        libxcomposite1 \
        libxcursor1 \
        libxi6 \
        libxkbcommon-x11-0 \
        libxkbcommon0 \
        libxrandr2 \
        libxrender1 \
        libxtst6 \
        mesa-utils \
        mesa-utils-extra \
        xdg-utils \
        # xpra \
        xsel \
        zenity && \
    echo "en_US.UTF-8 UTF-8" >/etc/locale.gen && \
    locale-gen

ARG VER=0.10.15

RUN cd /opt && \
    wget https://github.com/logseq/logseq/releases/download/$VER/Logseq-linux-arm64-$VER.zip && \
    unzip Logseq*.zip && \
    rm -f Logseq*.zip

RUN find /opt -type f -exec chmod a+r {} ';' && \
    find /opt -type d -exec chmod a+rx {} ';' && \
    ln -s /opt/Logseq-linux-*/Logseq /usr/local/bin/Logseq

# Install a dummy script as a system browser that just copies links to be open to clipboard (optional)
#RUN apt-get install -y --no-install-recommends xdg-utils xsel zenity && \
#    { echo '#!/bin/bash'; \
#      echo 'echo "$@" | xsel -b'; \
#      echo 'zenity --notification --text "Link copied: $@" --timeout 10'; } >/usr/local/bin/dummy-browser.sh && \
#    chmod a+rx /usr/local/bin/dummy-browser.sh && \
#    { echo '[Desktop Entry]'; \
#      echo 'Name=Dummy Browser'; \
#      echo 'Exec=/usr/local/bin/dummy-browser.sh %u'; \
#      echo 'Type=Application'; \
#      echo 'Terminal=false'; \
#      echo 'Categories=Network;WebBrowser;'; \
#      echo 'MimeType=x-scheme-handler/http;x-scheme-handler/https;'; \
#      echo 'X-MultipleArgs=false'; } >/usr/share/applications/dummy-browser.desktop && \
#    chmod a+r /usr/share/applications/dummy-browser.desktop && \
#    xdg-settings set default-web-browser dummy-browser.desktop

ENV LC_ALL=en_US.UTF-8 \
    GTK_IM_MODULE=fcitx5 \
    QT_IM_MODULE=fcitx5 \
    XMODIFIERS=@im=fcitx5 \
    DefaultIMModule=fcitx5

CMD Logseq \
      --force-device-scale-factor=2 \
      --enable-gpu-rasterization \
      --ignore-gpu-blocklist \
      --enable-zero-copy \
      --enable-drdc \
      --no-sandbox
