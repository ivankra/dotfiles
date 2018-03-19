FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

SHELL ["/bin/bash", "-x", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/bash \
    CONDA_DIR=/opt/conda \
    LANG=en_US.UTF-8 \
    PATH="/root/.dotfiles/bin:/opt/conda/bin:/usr/local/cuda/bin:${PATH}"

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
        g++ \
        gcc \
        gfortran \
        git \
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
        libpng-dev \
        libpng12-dev \
        libzmq3-dev \
        locales \
        net-tools \
        openmpi-bin \
        pkg-config \
        python \
        python-dev \
	python-pip \
        rsync \
        software-properties-common \
	screen \
        ssh \
        swig \
        sudo \
	tmux \
	traceroute \
        tzdata \
        unzip \
        vim \
        wget \
        zip \
        zlib1g-dev \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    locale-gen ${LANG}

ARG ANACONDA_URL=https://repo.continuum.io/miniconda/Miniconda3-4.4.10-Linux-x86_64.sh
ARG ANACONDA_SHA256=0c2e9b992b2edd87eddf954a96e5feae86dd66d69b1f6706a99bd7fa75e7a891
RUN mkdir -p ${CONDA_DIR} && \
    cd /tmp && \
    curl -s -o anaconda.sh "${ANACONDA_URL}" && \
    echo "${ANACONDA_SHA256}  anaconda.sh" | sha256sum -c - && \
    bash ./anaconda.sh -f -b -p ${CONDA_DIR} && \
    rm -f anaconda.sh

ADD environment.yml ${CONDA_DIR}/environment.yml
RUN conda update -y -n base conda && \
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

RUN jupyter nbextension enable --py widgetsnbextension && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager

ADD pkg/authorized_keys /root/.ssh/authorized_keys
ADD pkg/dotfiles /root/.dotfiles
RUN /root/.dotfiles/setup

EXPOSE 8888
ADD run.sh /run.sh
CMD /run.sh
