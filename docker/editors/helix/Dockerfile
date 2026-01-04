FROM editors-base

RUN HELIX_VERSION=$(curl -s https://api.github.com/repos/helix-editor/helix/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') && \
    ARCH=$(dpkg --print-architecture | sed 's/arm64/aarch64/') && \
    wget -O helix.tar.xz "https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-${ARCH}-linux.tar.xz" && \
    tar -xf helix.tar.xz && \
    mv helix-${HELIX_VERSION}-${ARCH}-linux helix && \
    mv helix/hx /usr/local/bin/ && \
    mkdir -p /root/.config/helix && \
    mv helix/runtime /root/.config/helix/ && \
    rm -rf helix helix.tar.xz

RUN persist-root.sh
ENTRYPOINT ["persist-root.sh", "hx"]
