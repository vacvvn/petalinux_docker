FROM ubuntu:18.04

# if you don't want default params, you can
# build with "docker build --build-arg PETA_VERSION=2020.2 --build-arg PETA_RUN_FILE=petalinux-v2020.2-final-installer.run -t petalinux:2020.2 ."
ARG PETA_VERSION="2018.3"
ARG PETA_RUN_FILE="petalinux-v2018.3-final-installer.run"
ARG PETA_DIST_PATH="/home/vivado/dist"
ARG PETA_INST_PATH="/home/vivado/Xilinx/petalinux"

# repositories
RUN echo 'deb http://lrepo.module.ru/repository/ubuntu/ bionic main restricted universe multiverse' >/etc/apt/sources.list && \
echo 'deb http://lrepo.module.ru/repository/ubuntu/ bionic-updates main restricted universe  multiverse' >>/etc/apt/sources.list && \
echo 'deb http://lrepo.module.ru/repository/ubuntu/ bionic-security main restricted universe multiverse' >>/etc/apt/sources.list

# install dependences:
RUN apt-get update &&  DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  build-essential \
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
  python 
# && apt-get clean \
# && rm -rf /var/lib/apt/lists/*

RUN dpkg --add-architecture i386 &&  apt-get update &&  \
      DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
      zlib1g:i386 
#    && apt-get clean \
#    && rm -rf /var/lib/apt/lists/*
#locale!
RUN locale-gen en_US.UTF-8 && update-locale

#make a Vivado user
RUN adduser --disabled-password --gecos '' --uid 1000 vivado && \
  usermod -aG sudo vivado && \
  echo "vivado ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# distributive and eula handler script
COPY installer/accept-eula.sh installer/${PETA_RUN_FILE} ${PETA_DIST_PATH}/

# run the install
RUN chmod a+rwx ${PETA_DIST_PATH}/${PETA_RUN_FILE}
RUN chmod a+rwx ${PETA_DIST_PATH}/accept-eula.sh 
RUN mkdir -p ${PETA_INST_PATH}/${PETA_VERSION}
RUN chmod 775 ${PETA_INST_PATH}/${PETA_VERSION}
RUN chmod 775 ${PETA_INST_PATH}
RUN chown -R vivado:vivado /home/vivado 
RUN cd ${PETA_DIST_PATH}
  # echo "==========Start installing==============" && \
RUN sudo -u vivado -i ${PETA_DIST_PATH}/accept-eula.sh ${PETA_DIST_PATH}/${PETA_RUN_FILE} ${PETA_INST_PATH}/${PETA_VERSION}
RUN  rm -f ${PETA_DIST_PATH}/${PETA_RUN_FILE} ${PETA_DIST_PATH}/accept-eula.sh 
RUN rm -rf ${PETA_DIST_PATH}

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

USER vivado
ENV HOME /home/vivado
ENV LANG en_US.UTF-8
RUN mkdir /home/vivado/project
WORKDIR /home/vivado/project

#add vivado tools to path
RUN echo "source ${PETA_INST_PATH}/${PETA_VERSION}/settings.sh" >> /home/vivado/.bashrc
