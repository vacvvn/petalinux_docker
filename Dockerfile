FROM ubuntu:16.04

#UID пользователя по умолчанию
ARG UID_val=1000
#GID пользователя по умолчанию
ARG GID_val=1000
#имя пользователя по умолчанию
ARG LOGIN_str="vivado"
# if you don't want default params, you can
# build with "docker build --build-arg PETA_VERSION=2020.2 --build-arg PETA_RUN_FILE=petalinux-v2020.2-final-installer.run -t petalinux:2020.2 ."
ARG PETA_VERSION="2018.3"
ARG PETA_RUN_FILE="petalinux-v2018.3-final-installer.run"
ARG PETA_INST_PATH="/home/${LOGIN_str}/Xilinx/petalinux"


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

#make a user. GID и UID будут по умолчанию или из параметров сборки образа
RUN  groupadd -g ${GID_val} ${LOGIN_str} && \
  adduser --disabled-password --gecos '' --uid ${UID_val} --gid ${GID_val} ${LOGIN_str} && \
  usermod -aG sudo ${LOGIN_str} && \
  echo "${LOGIN_str} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

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
 chown -R ${LOGIN_str}:${LOGIN_str} /home/${LOGIN_str}  && \
 cd /tmp && \
 sudo -u ${LOGIN_str} -i /distr/accept-eula.sh /distr/${PETA_RUN_FILE} ${PETA_INST_PATH}/${PETA_VERSION}/main && \
 rm -rf /tmp/* && \
 # для уменьшения размера можно убрать локальный sstate и bsp из образа.
 tar -xf /distr/sstate-rel-v2018.3.tar.gz  --directory=${PETA_INST_PATH}/${PETA_VERSION}/sstate/ && \
 cp /distr/xilinx-zcu102-v2018.3-final.bsp ${PETA_INST_PATH}/${PETA_VERSION}/bsp/ 

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
 DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash && \
 rm -rf /distr

USER ${LOGIN_str}
ENV HOME /home/${LOGIN_str}
ENV LANG en_US.UTF-8
RUN mkdir /home/${LOGIN_str}/project
# шаблон скрипта сборки компонента
WORKDIR /home/${LOGIN_str}/project
COPY --chown=${UID_val}:${GID_val} --chmod=766 installer/component_update.sh /home/${LOGIN_str}/useful_files/component_update.sh

#add ${LOGIN_str} tools to path
RUN echo "source ${PETA_INST_PATH}/${PETA_VERSION}/main/settings.sh" >> /home/${LOGIN_str}/.bashrc
