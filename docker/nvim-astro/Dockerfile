FROM editors-base

RUN git clone --depth=1 https://github.com/AstroNvim/template ~/.config/nvim && \
    rm -rf ~/.config/nvim/.git

RUN nvim --headless "+Lazy! sync" "+qa"
RUN nvim --headless "+MasonInstallAll" "+qa"
#RUN nvim --headless "+TSInstallSync all" "+qa"

RUN persist-root.sh
ENTRYPOINT ["persist-root.sh", "nvim"]
