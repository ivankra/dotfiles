FROM agents-base

# Official installer (https://www.kimi.com/code/en). It drops the native binary
# in $KIMI_INSTALL_DIR/bin; install to /usr/local so it survives the /root
# volume mount. Config still lives in the mounted /root/.kimi-code.
RUN KIMI_INSTALL_DIR=/usr/local KIMI_NO_MODIFY_PATH=1 \
        bash -c 'curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash'

CMD kimi
