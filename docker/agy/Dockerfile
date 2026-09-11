FROM agents-base

# Official installer (https://antigravity.google/docs/cli/install/). It defaults
# to ~/.local/bin; --dir puts the binary in /usr/local/bin instead, so it
# survives the /root volume mount. The installer's final `agy install` step only
# edits shell rc files and is allowed to fail.
RUN curl -fsSL https://antigravity.google/cli/install.sh | \
        bash -s -- --dir /usr/local/bin

CMD agy
