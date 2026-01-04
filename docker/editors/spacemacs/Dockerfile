FROM editors-base

RUN git clone --depth=1 https://github.com/syl20bnr/spacemacs.git /root/.emacs.d

RUN echo "(defun dotspacemacs/layers () (setq-default dotspacemacs-distribution 'spacemacs dotspacemacs-editing-style 'vim))" >/root/.spacemacs
RUN emacs --batch -l /root/.emacs.d/init.el -eval "(configuration-layer/update-packages t)"
RUN emacs --batch -l /root/.emacs.d/init.el --kill
RUN persist-root.sh
ENTRYPOINT ["persist-root.sh", "emacs"]
