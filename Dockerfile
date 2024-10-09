FROM ubuntu:16.04

# if you don't want default params, you can
# build with "docker build --build-arg PETA_VERSION=2020.2 --build-arg PETA_RUN_FILE=petalinux-v2020.2-final-installer.run -t petalinux:2020.2 ."
ARG PETA_VERSION="2018.3"
ARG PETA_RUN_FILE="petalinux-v2018.3-final-installer.run"
ARG PETA_INST_PATH="/home/vivado/Xilinx/petalinux"

# repositories
RUN echo 'deb http://lrepo.module.ru/repository/ubuntu/ xenial main restricted universe multiverse' >/etc/apt/sources.list && \
echo 'deb http://lrepo.module.ru/repository/ubuntu/ xenial-updates main restricted universe  multiverse' >>/etc/apt/sources.list && \
echo 'deb http://lrepo.module.ru/repository/ubuntu/ xenial-security main restricted universe multiverse' >>/etc/apt/sources.list

# install dependences:
RUN apt-get update &&  DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  build-essential \
  make \
  gcc \
  sudo \
  apt-utils \
  tofrodos \
  iproute2 \
  gawk \
  net-tools \
  expect \
  libncurses5-dev \
  tftpd \
  update-inetd \
  libssl-dev \
  flex \
  bison \
  libselinux1 \
  gnupg \
  wget \
  socat \
  gcc-multilib \
  libidn11 \
  libsdl1.2-dev \
  libglib2.0-dev \
  lib32z1-dev \
  libgtk2.0-0 \
  libtinfo5 \
  screen \
  pax \
  tar \
  diffstat \
  xvfb \
  xterm \
  texinfo \
  gzip \
  unzip \
  cpio \
  chrpath \
  autoconf \
  lsb-release \
  libtool \
  libtool-bin \
  locales \
  kmod \
  git \
  rsync \
  bc \
  u-boot-tools \
  python && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

RUN dpkg --add-architecture i386 && \
  apt-get update &&  \
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
      zlib1g:i386 zlib1g-dev && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* 

RUN  locale-gen en_US.UTF-8 && update-locale

#make a Vivado user
RUN  adduser --disabled-password --gecos '' --uid 1000 vivado && \
  usermod -aG sudo vivado && \
  echo "vivado ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# distributive and eula handler script
#COPY installer/accept-eula.sh installer/${PETA_RUN_FILE} ${PETA_DIST_PATH}/
#COPY installer/xilinx-zcu102-v2018.3-final.bsp ${PETA_INST_PATH}/${PETA_VERSION}/bsp/
# run the install
RUN --mount=type=bind,source=installer/,target=/distr/ \
 mkdir -p ${PETA_INST_PATH}/${PETA_VERSION}/bsp && \
 mkdir -p ${PETA_INST_PATH}/${PETA_VERSION}/sstate && \
 mkdir -p ${PETA_INST_PATH}/${PETA_VERSION}/main && \
 chmod -R 775 ${PETA_INST_PATH} && \
 chmod -R 777 /tmp && \
 chown -R vivado:vivado /home/vivado  && \
 cd /tmp && \
 sudo -u vivado -i /distr/accept-eula.sh /distr/${PETA_RUN_FILE} ${PETA_INST_PATH}/${PETA_VERSION}/main && \
 rm -rf /tmp/* && \
 tar -xf /distr/sstate-rel-v2018.3.tar.gz  --directory=${PETA_INST_PATH}/${PETA_VERSION}/sstate/ && \
 cp /distr/xilinx-zcu102-v2018.3-final.bsp ${PETA_INST_PATH}/${PETA_VERSION}/bsp/ 

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
 DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash && \
 rm -rf /distr

USER vivado
ENV HOME /home/vivado
ENV LANG en_US.UTF-8
RUN mkdir /home/vivado/project
WORKDIR /home/vivado/project

#add vivado tools to path
RUN echo "source ${PETA_INST_PATH}/${PETA_VERSION}/main/settings.sh" >> /home/vivado/.bashrc 
