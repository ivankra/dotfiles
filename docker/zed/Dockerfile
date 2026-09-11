# Zed: a high-performance, multiplayer code editor from the creators of Atom and Tree-sitter.
#
# Note: GPU-accelerated with Vulkan.
# Works with software rasterizer but slow/CPU-intensive.

FROM debian:stable

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        wget \
        libasound2 \
        libdbus-1-3 \
        libegl1 \
        libfontconfig1 \
        libgl1 \
        libglib2.0-0 \
        libvulkan1 \
        libxcb1 \
        libxcb-cursor0 \
        libxcb-randr0 \
        libxcb-shape0 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxi6 \
        libxkbcommon0 \
        libxkbcommon-x11-0 \
        libxrandr2 \
        libxrender1 \
        libxtst6 \
        mesa-vulkan-drivers

RUN ARCH=$(uname -m | sed 's/x86_64/x86_64/; s/aarch64/aarch64/') && \
    cd /tmp && \
    wget -O zed-linux.tar.gz "https://cloud.zed.dev/releases/stable/latest/download?asset=zed&arch=${ARCH}&os=linux" && \
    tar -xzf zed-linux.tar.gz -C /opt && \
    rm zed-linux.tar.gz && \
    ln -s /opt/zed.app/bin/zed /usr/local/bin/zed

ENTRYPOINT ["zed", "--foreground"]
