FROM editors-base

RUN apt-get update -y && \
    apt-get install -y cargo luarocks

RUN luarocks install lua-utils
RUN cargo install --locked --git https://github.com/Feel-ix-343/markdown-oxide.git markdown-oxide

ENV PATH="/root/.cargo/bin:${PATH}"
