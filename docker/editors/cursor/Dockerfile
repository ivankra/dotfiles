FROM editors-base

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libasound2t64 \
        libatk-bridge2.0-0t64 \
        libatk1.0-0t64 \
        libatspi2.0-0t64 \
        libcairo2 \
        libcups2t64 \
        libcurl4t64 \
        libdbus-1-3 \
        libexpat1 \
        libgbm1 \
        libglib2.0-0t64 \
        libgtk-3-0t64 \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libudev1 \
        libvulkan1 \
        libx11-6 \
        libxcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxkbcommon0 \
        libxkbfile1 \
        libxrandr2 \
        xdg-utils

RUN ARCH=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/') && \
    wget -O /tmp/cursor.deb "https://api2.cursor.sh/updates/download/golden/linux-${ARCH}-deb/cursor/"

RUN apt-get update && \
    apt-get install -y /tmp/cursor.deb && \
    rm /tmp/cursor.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["cursor", "--wait", "--no-sandbox", "--password-store=basic"]
