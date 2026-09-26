# OpenKnowledge: WYSIWYG markdown knowledge base with AI-assisted editing.
# Electron app, installed from the upstream .deb release.

FROM editors-base

RUN ARCH=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/') && \
    wget -O /tmp/openknowledge.deb \
      "https://github.com/inkeep/open-knowledge/releases/latest/download/OpenKnowledge-${ARCH}.deb"

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends \
        /tmp/openknowledge.deb \
        fonts-dejavu-core \
        fonts-noto-cjk \
        fonts-noto-color-emoji \
        fonts-noto-core \
        git-lfs \
        jq \
        pandoc \
        poppler-utils \
        python3-bs4 \
        python3-lxml \
        python3-pip \
        xclip && \
    rm /tmp/openknowledge.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# AI harnesses for OpenKnowledge's side-by-side editing.
# Installed as root; their state lives in the persisted $HOME (~/.claude, ~/.codex).
RUN curl -fsSL https://claude.ai/install.sh | bash && \
    cp -L /root/.local/bin/claude /usr/local/bin/claude && \
    rm -rf /root/.local/share/claude /root/.local/bin/claude && \
    npm install -g @openai/codex

# GLYCIN_DISABLE_SANDBOX needs glycin >= 2.2, to work around gdk-pixbuf loading
# icons via glycin which sandboxes with bwrap and can't work under docker.
# DISABLE_AUTOUPDATER: claude lives in root-owned /usr/local/bin, the container runs as the host user.
ENV LC_ALL=en_US.UTF-8 \
    GLYCIN_DISABLE_SANDBOX=i-know-the-risks \
    DISABLE_AUTOUPDATER=1

ENTRYPOINT ["openknowledge", "--no-sandbox", "--password-store=basic"]
