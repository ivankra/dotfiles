FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

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
        bsdmainutils \
        build-essential \
        byobu \
        bzip2 \
        ca-certificates \
        cmake \
        curl \
        dnsutils \
        ffmpeg \
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
        iproute2 \
        iputils-ping \
        less \
        libav-tools \
        libcairo2-dev \
        libcurl3-dev \
        libfreetype6-dev \
        libgl1-mesa-glx \
        libjpeg-dev \
        libhdf5-dev \
        liboctave-dev \
        libpng-dev \
        libpng12-dev \
        libzmq3-dev \
        locales \
        netpbm \
        net-tools \
        openmpi-bin \
        pkg-config \
        python \
        python-dev \
        python-pip \
        p7zip-full \
        rsync \
        software-properties-common \
        screen \
        ssh \
        sshfs \
        swig \
        sudo \
        tmux \
        traceroute \
        tzdata \
        unzip \
        vim \
        vim-gtk3 \
        wget \
        xauth \
        xpra \
        xsel \
        zip \
        zlib1g-dev \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo "en_US.UTF-8 UTF-8" >/etc/locale.gen && \
    locale-gen && \
    passwd -d root

ARG NB_USER=user
ARG NB_GID=1000
ARG NB_UID=1000
ARG ANACONDA_URL=https://repo.continuum.io/miniconda/Miniconda3-4.4.10-Linux-x86_64.sh
ARG ANACONDA_SHA256=0c2e9b992b2edd87eddf954a96e5feae86dd66d69b1f6706a99bd7fa75e7a891

ENV CONDA_DIR=/opt/conda \
    PATH="/root/.dotfiles/bin:/opt/conda/bin:/usr/local/cuda/bin:${PATH}"

RUN groupadd --gid ${NB_GID} ${NB_USER} && \
    useradd --uid ${NB_UID} --gid ${NB_GID} --shell /bin/bash --create-home --no-log-init ${NB_USER} && \
    mkdir -p ${CONDA_DIR} /usr/local/share/jupyter && \
    chown -R ${NB_UID}:${NB_GID} ${CONDA_DIR} /home/${NB_USER} /usr/local/share/jupyter

USER ${NB_USER}

ADD environment.yml ${CONDA_DIR}/environment.yml
RUN mkdir -p ${CONDA_DIR} && \
    cd /tmp && \
    curl -s -o anaconda.sh "${ANACONDA_URL}" && \
    echo "${ANACONDA_SHA256}  anaconda.sh" | sha256sum -c - && \
    bash ./anaconda.sh -f -b -p ${CONDA_DIR} && \
    rm -f anaconda.sh && \
    conda update -y -n base conda && \
    conda env update -n base -f ${CONDA_DIR}/environment.yml && \
    { \
      if [[ "${ANACONDA_URL}" == *conda3* ]]; then \
        conda create -y -n py27 python=2.7 && \
        conda env update -n py27 -f ${CONDA_DIR}/environment.yml && \
        /opt/conda/envs/py27/bin/python -m ipykernel install; \
      else \
        conda create -y -n py36 python=3.6 && \
        conda env update -n py36 -f ${CONDA_DIR}/environment.yml && \
        /opt/conda/envs/py36/bin/python -m ipykernel install; \
      fi; \
    } && \
    conda clean -a -y

ADD environment-r.yml ${CONDA_DIR}/environment-r.yml
RUN conda env update -n base -f ${CONDA_DIR}/environment-r.yml

RUN python -m spacy download en && \
    jupyter contrib nbextension install --user && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager

#jupyter nbextension enable --py widgetsnbextension && \
#jupyter nbextensions_configurator enable --user
#jupyter contrib nbextension install --user
#RUN pip install cupy

USER root
ADD pkg/authorized_keys /root/.ssh/authorized_keys
ADD pkg/dotfiles /root/.dotfiles
RUN /root/.dotfiles/setup && \
    cp -a /root/.dotfiles /root/.ssh /home/${NB_USER}/ && \
    chmod -R og-rwx /root/.ssh /home/${NB_USER}/.ssh && \
    /root/.dotfiles/setup && \
    chown -R ${NB_UID}:${NB_GID} ${CONDA_DIR} /home/${NB_USER} /mnt /usr/local/share/jupyter && \
    sudo --login -u ${NB_USER} /home/${NB_USER}/.dotfiles/setup

EXPOSE 22 8888
ADD run.sh /run.sh
CMD /run.sh

ENTRYPOINT ["/run.sh"]
CMD [""]

# vim: et
