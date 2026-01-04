FROM lazyvim

WORKDIR /root

RUN curl -s -o /tmp/install.sh https://raw.githubusercontent.com/lunarvim/lunarvim/release-1.4/neovim-0.9/utils/installer/install.sh && \
    bash /tmp/install.sh

RUN ln -s /root/.local/bin/lvim /usr/local/bin/lvim
RUN persist-root.sh
ENTRYPOINT ["persist-root.sh", "lvim"]
