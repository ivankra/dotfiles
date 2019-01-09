# Container for running anaconda with jupyter/jupyterlab on nvidia-docker
# Sets up non-root user, ssh, optionally accepts external conda installation dirs.

FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

SHELL ["/bin/bash", "-x", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/bash \
    LANG=en_US.UTF-8

RUN apt-get clean && \
    apt-get update -y -q && \
    apt-get install -y -q --no-install-recommends curl && \
    if curl "http://s/ubuntu/" 2>&1 | grep -q Apt-Cacher-NG; then \
      sed -E -i -e "s/(archive|security).ubuntu.com/s/" /etc/apt/sources.list; \
    fi

RUN apt-get clean && \
    apt-get update -y -q && \
    apt-get install -y -q --no-install-recommends \
        aptitude \
        bc \
        bsdmainutils \
        build-essential \
        byobu \
        bzip2 \
        ca-certificates \
        cmake \
        curl \
        dnsutils \
        ffmpeg \
        file \
        fonts-dejavu \
        fonts-liberation \
        fonts-mplus \
        g++ \
        gcc \
        gdb \
        gfortran \
        git \
        gnuplot \
        graphviz \
        imagemagick \
        iproute2 \
        iputils-ping \
        less \
        libcairo2-dev \
        libcurl3-dev \
        libfreetype6-dev \
        libgl1-mesa-glx \
        libhdf5-dev \
        libjpeg-dev \
        liboctave-dev \
        libpng-dev \
        libssl-dev \
        libxml2-dev \
        libzmq3-dev \
        locales \
        mercurial \
        net-tools \
        netpbm \
        octave \
        openmpi-bin \
        pandoc \
        parallel \
        patch \
        p7zip-full \
        pkg-config \
        poppler-utils \
        psmisc \
        python \
        python-dev \
        python-pip \
        rsync \
        screen \
        software-properties-common \
        ssh \
        sshfs \
        strace \
        subversion \
        sudo \
        swig \
        tmux \
        traceroute \
        tzdata \
        unzip \
        vim \
        vim-gtk3 \
        wget \
        whois \
        xauth \
        xsel \
        zip \
        zlib1g-dev \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo "en_US.UTF-8 UTF-8" >/etc/locale.gen && \
    locale-gen && \
    passwd -d root

ENV CONDA_DIR=/opt/conda \
    PATH="/opt/conda/bin:/usr/local/cuda/bin:${PATH}"

ARG NB_USER=lab
ARG NB_UID=1000
ARG NB_GID=1000
ARG INSTALLER_URL1="http://s/packages/Miniconda3-4.5.12-Linux-x86_64.sh"
ARG INSTALLER_URL2="https://repo.anaconda.com/miniconda/Miniconda3-4.5.12-Linux-x86_64.sh"
ARG INSTALLER_HASH="e5e5b4cd2a918e0e96b395534222773f7241dc59d776db1b9f7fedfcb489157a"

RUN groupadd --gid ${NB_GID} ${NB_USER} && \
    useradd --uid ${NB_UID} --gid ${NB_GID} --groups sudo --shell /bin/bash --create-home --no-log-init ${NB_USER} && \
    mkdir -p ${CONDA_DIR} /usr/local/share/jupyter && \
    chown -R ${NB_UID}:${NB_GID} ${CONDA_DIR} /home/${NB_USER} /usr/local/share/jupyter

USER ${NB_USER}

RUN mkdir -p ${CONDA_DIR} && \
    ((curl -s -o /tmp/anaconda.sh "${INSTALLER_URL1}" && \
     echo "${INSTALLER_HASH}  /tmp/anaconda.sh" | sha256sum --quiet -c -) || \
     (curl -s -o /tmp/anaconda.sh "${INSTALLER_URL2}" && \
      echo "${INSTALLER_HASH}  /tmp/anaconda.sh" | sha256sum --quiet -c -)) && \
    bash /tmp/anaconda.sh -f -b -u -p ${CONDA_DIR} && \
    rm -f /tmp/anaconda.sh
ADD environment.yml ${CONDA_DIR}/environment.yml
RUN conda env update -n base -f ${CONDA_DIR}/environment.yml && \
    conda clean -a -y
RUN jupyter contrib nbextension install --user && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager

USER root

ADD .dotfiles /root/.dotfiles
RUN mkdir -m 0700 -p /root/.ssh && \
    cp -a /root/.dotfiles/authorized_keys /root/.ssh/ && \
    cp -a /root/.dotfiles /root/.ssh /home/${NB_USER}/ && \
    chmod -R og-rwx /root/.ssh /home/${NB_USER}/.ssh && \
    /root/.dotfiles/setup && \
    find ${CONDA_DIR} /home/${NB_USER} /usr/local/share/jupyter '!' -user ${NB_UID} -exec chown ${NB_UID}:${NB_GID} '{}' ';' && \
    mkdir -p /work && ln -s /work /home/${NB_USER}/work && \
    chown -h ${NB_UID}:${NB_GID} /work /home/${NB_USER}/work && \
    sudo --login -u ${NB_USER} /home/${NB_USER}/.dotfiles/setup

EXPOSE 22 8888
ADD run.sh /run.sh
CMD /run.sh

ENTRYPOINT ["/run.sh"]
CMD [""]

# vim: et
