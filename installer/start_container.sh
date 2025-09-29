#!/bin/bash

# скрипт запускает контейнер и монтирует текущую директорию в контейнер
# по пути /home/vivado/project
# Скрипт можно использовать для создания и конфигурации нового проекта,
# создания компонентов, копирования скрипта component_update.sh в директорию
# проекта и запуска других команд из состава petalinux(см ug1144)

cur_dir=`pwd`
plnx_image="plnx-tools-1.0.0:latest"
echo -e "Current dir: $cur_dir; petalinux image: $plnx_image"
docker run -it --rm --mount type=bind,source=$cur_dir,target=/home/vivado/project $plnx_image
