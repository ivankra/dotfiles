FROM editors-base


RUN apt-get update -y && \
    apt-get install -y cargo luarocks

RUN luarocks install lua-utils
RUN cargo install --locked --git https://github.com/Feel-ix-343/markdown-oxide.git markdown-oxide

ENV PATH="/root/.cargo/bin:${PATH}"

# RUN git clone https://github.com/ivankra/dotfiles.git /root/.dotfiles && cd /root/.dotfiles/modules && make
# RUN /root/.dotfiles/setup.sh
