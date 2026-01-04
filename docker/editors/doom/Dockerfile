FROM editors-base

RUN git clone --depth=1 https://github.com/doomemacs/doomemacs /root/.emacs.d

ENV PATH="/root/.emacs.d/bin:${PATH}"
RUN /root/.emacs.d/bin/doom install --no-env
RUN /root/.emacs.d/bin/doom sync
RUN persist-root.sh
ENTRYPOINT ["persist-root.sh", "emacs"]
