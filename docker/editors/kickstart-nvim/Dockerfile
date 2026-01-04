FROM editors-base

RUN git clone --depth=1 https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim && \
    rm -rf ~/.config/nvim/.git

RUN sed -i 's/nvim-treesitter.configs/nvim-treesitter.config/' ~/.config/nvim/init.lua

RUN nvim --headless "+Lazy! update" "+qa"
RUN nvim --headless "+TSUpdate!" "+qa"
RUN persist-root.sh
ENTRYPOINT ["persist-root.sh", "nvim"]
