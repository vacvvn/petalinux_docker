---
type: petalinux
aliases:
  - petalinux 2018.3 docker container
tags:
  - todo
  - petalinux
  - project
  - xilinx
---
___
# общие сведения
Комплект для сборки docker образа в котором будут установлены:
- ubuntu 16.04
- petalinux 2018.3 - toolkit для разработки ПО
- sstate-rel-v2018.3.tar.gz - полный набор зависимостей для сборки(необязательно)
- xilinx-zcu102-v2018.3-final.bsp - board support package для отладочной платы zcu-102(необязательно)

>Dockerfile создан на основе [примера](https://github.com/z4yx/petalinux-docker/blob/master/Dockerfile)

команды для создания и управления проектом изложены в документах:
- [ug1144](https://docs.amd.com/v/u/2018.3-English/ug1144-petalinux-tools-reference-guide)
- [ug1157](https://docs.amd.com/v/u/2018.3-English/ug1157-petalinux-tools-command-line-guide)

> [!NOTE] Внимание
> В репозитории отсутствует установочный файл `installer/petalinux-v2018.3-final-installer.run,` файл Board support package `installer/xilinx-zcu102-v2018.3-final.bsp` и файл с зависимостями `installer/sstate-rel-v2018.3.tar.gz`.
> - Для **минимальной сборки** образа в директорию `installer` достаточно поместить **только** `petalinux-v2018.3-final-installer.run`. В таком случае требуется закомментировать в `Dockerfile` копирование в образ `bsp` и `sstate` файлов

> [!NOTE] Важно
> Если образ **не включает** файл `bsp` и архив `sstate`:
> - при запуске контейнера в него нужно **обязательно** смонтировать, кроме директории с вложенной папкой проекта, еще одну внешнюю директорию, где расположен `bsp` файл.
> - желательно смортировать в контейнер внешнюю папку с файлом зависимостей `sstate`, а при конфигурации проекта нужно указать путь к этой папке.

# быстрый старт

- распаковать архив
```bash
tar -xf plnx-tools-1.0.0.tar
```
- собрать образ:
```bash
	cd petalinux2018
	docker image build -t plnx-tools-1.0.0:latest .
```
- в директории `installer` лежит вспомогательный скрипт запуска контейнера `start_container.sh`. Скрипт монтирует в контейнер папку, в которой он запущен. Путь монтирования в контейнере: `/home/vivado/project`
- запустить контейнер
```bash
	docker run -it --rm \
	--mount type=bind,source=/absolute/path/to/host/folder,target=/home/vivado/project \
plnx-tools-1.0.0:latest
```
- после запуска контейнера, в директории `/home/vivado/useful_files`   появится шаблон впомогательного скрипта `component_update.sh`
	- этот скрипт следует скопировать в директорию `/home/vivado/project` и тогда он станет виден в хосте.
	- переименовать, отредактировать этот скрипт и запускать **на хосте** для сборки компонентов. Скрипт сам запустит контейнер и передаст в него команды `petalinux-build -c .....`.
- после запуска контейнера, в папке `/home/vivado` для появится вспомогательный скрипт `start_container.sh`.
	- скопировать скрипт в директорию `/home/vivado/project`. После запуска скрипта текущая папка будет смонтирована в контейнер
	- этот же скрипт можно найти в папке `installer` папки сборки образа контейнера.
- [[#создать проект|создавать проект]] следует в директории `/home/vivado/project`
	- запустить контейнер и в нем давать команды `petalinux-create -t project....`
# параметры по умолчанию
В Dockerfile заданы параметры по умолчанию:
- *UID_val*: UID пользователя, под которым будет создаваться проект
    - по умолчанию 1000
- *GID_val*: GID пользователя, для которой будет создаваться проект
    - по умолчанию 1000
- *LOGIN_str*: имя пользователя
    - по умолчанию vivado
- *PETA_VERSION*: версия petalinux
    - по умолчанию 2018.3
- *PETA_RUN_FILE*: установочный файл petalinux
- *PETA_INST_PATH*: путь для установки системы сборки, зависимостей и bsp

>[!NOTE] Важно
>Если параметры по умолчанию не подходят, придется пересобирать образ с новыми параметрами.
>Любой параметр можно изменить либо в Dockerfile, либо задать в виде параметра ком.строки при сборке нового образа. Пример команды для сборки образа:
> ```bash
> docker build --build-arg GID_val=1234  --build-arg UID_val=1234 -t plnx-tools-1.0.0:latest .
> ```
# сборка образа
Если не требуется задавать особые параметры, команда сборки образа может выглядеть следующим образом:
```bash
docker build -t plnx-tools-1.0.0:latest .
```
>При сборке образа в него копируется файл `bsp` для платы `zcu102`. После запуска контейнера этот файл используется для создания проектов. Если этот файл не требуется, его можно удалить из директории `installer` и закомментировать соответствующую строку в `Dockerfile`.
>По умолчанию архив `bsp` будет распакован в директорию `/home/vivado/Xilinx/petalinux/2018.3/bsp/`

>При сборке образа в него распаковывается архив зависимостей `sstate`. После запуска контейнера этот архив используется для сборки проектов. Для его использования при **конфигурации** проекта в разделе `Yocto Setting->Local sstate feeds settings` нужно прописать путь до директории `aarch64` из распакованного архива.
>Если этот файл не требуется, его можно удалить из директории `installer` и закомментировать соответствующую строку в `Dockerfile`.
>По умолчанию архив `sstate` будет распакован в директорию `/home/vivado/Xilinx/petalinux/2018.3/sstate/`
## размер образа
>Размер образа составляет примерно 50ГБ.

При сборке образа файл зависимостей и bsp-файл копируются в образ, но не участвуют в установке и сборке.  Т.о. для уменьшения размера образа можно изменить Dockerfile:
- можно закомментировать распаковку архива `sstate` в образ.
    - В этом случае при сборке проекта система сборки будет скачивать зависимости с внешних ресурсов.
    - если `sstate` уже присутствуют на хост системе, можно смонтировать эту директорию в контейнер при его запуске. Для ее использования при конфигурации проекта в разделе `Yocto Setting->Local sstate feeds settings` нужно прописать путь до поддиректории aarch64 смонтированной директории.
- Если файл `bsp` есть на хосте, то можно закомментировать копирование в образ файла `bsp`
    - В этом случае при создании проекта папка с внешним `bsp` файлом должна быть смонтирована в контейнер.

# запуск контейнера
Предполагается, что контейнер будет запускаться с монтированием рабочей директории хоста в контейнер. В этой директории будут создаваться, собираться и модифицироваться проекты.

>Предпочтительно, чтобы UID/GID владельца примонтированной внешней директории совпадал с UID/GID под которыми в контейнер установлен petalinux и под которыми будет создаваться проект. Если UID/GID не совпадают, можно пересобрать образ под [[#параметры по умолчанию|нужные параметры]]

Пример команды запуска контейнера:
```bash
# проектная директория хоста смонтируется в директорию /home/vivado/project контейнера
docker run -it --rm --mount type=bind,source=/absolute/path/to/project/folder/,target=/home/vivado/project  plnx-tools-1.0.0:latest
```
>В директории `/home/vivado` можно найти вспомогательный скрипт `start_container.sh`, который запустит контейнер и примонтирует туда текущую папку.
# создание, конфигурация и сборка проекта
Например, внешняя директория хоста смотрирована в контейнер по пути `/home/vivado/project`. Если для создания проекта используется `hdf` файл, то его нужно скопировать в директорию `project`. Предполагается, что `sstate` и `bsp` скопированы в образ и являются локальными для контейнера.
В таком случае команды для создания проекта должны выглядеть следующим образом:

## создать проект

> [!NOTE] Внимание
> опыт показал, если на хосте открыта директория проекта, которая смонтирована в контейнер, то сборка и конфигурация могут завершаться ошибкой.  В таком случае нужно закрыть директорию проекта на хосте и запустить конфигурацию или сборку заново.

```bash
$petalinux-create -t project -s /home/vivado/Xilinx/petalinux/2018.3/bsp/xilinx-zcu102-v2018.3-final.bsp
INFO: Create project:
INFO: Projects:
INFO:   * xilinx-zcu102-2018.3
INFO: has been successfully installed to /home/vivado/project/
INFO: New project successfully created in /home/vivado/project/
```
В результате в текущем каталоге появится корневой каталог проекта: `xilinx-zcu102-2018.3`
## сконфигурировать проект
 - перейти в корневую директорию нового проекта (в примере `xilinx-zcu102-2018.3`)
```bash
cd xilinx-zcu102-2018.3
```
- задать файл с описанием прошивки ПЛИС в формате .hdf
```bash
# hdf в папке уровнем выше - project
petalinux-config --get-hw-description=../
```
>[!NOTE] примечание для платы ZCU102
>Из файлов ПЛИС достаточно взять только файл `hdf`. Из него `petalinux` сгенерирует `.bit` файл. Так же, не обязательно брать из ПЛИС файл `FSBL.elf`. После сборки ядра рабочий загрузчик `zynqmp_fsbl.elf` появится в `images/linux`

В результате выполнения команды появится окно конфигурирования ядра `menuconfig`. Для сборки ядра, которое **загружается с SD-карты** необходимо:
 - Заменить шаблон файла дерева устройств `<PetaLinux-project>/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi` на рабочий файл.
- Перейти в `Subsystem AUTO Hardware Settings -> Advanced Bootable Images Storage Settings`
	- `boot image settings -> Image Storage Media` выбрать пункт `primary SD`
	- `kernel image settings -> image storage media` выбрать пункт `primary SD`
- перейти в `Subsystem AUTO Hardware Settings -> Memory settings -> System Memory Size`
	- установить значение `0x80000000`
 - перейти в меню `Yocto Settings -> Local sstate feeds settings -> local sstate feeds url`
	 - и прописать в него полный путь до папки `aarch64` из папки с зависимостями `/home/vivado/Xilinx/petalinux/2018.3/sstate/sstate-rel-v2018.3/aarch64/`
 - перейти в меню `Yocto Settings`
	 - снять отметку с пункта `Enable Network sstate feeds`
	 - чтобы отменить ввод пароля после перезагрузки нужно активировать пункт `Enable Debug tweaks`
 - перейти в меню `Image Packaging Configuration -> Root filesystem type` ^46ca44
	 - выбрать расположение `rootfs` - `SD card`
	 - если так не сделать, новые настройки и скачанные/созданные файлы будут **пропадать** после перезагрузки
 - перейти в меню `Image Packaging Configuration`
	 - снять отметку с пункта `Copy final images to tftpboot`
- если при сборке проекта требуются **внешние исходники ядра**, то при конфигурации можно указать путь к директории с внешними исходниками ядра
	- перейти в меню `Linux Components Selection -> linux-kernel`
		- выбрать пункт `ext-local-src`
		- при этом станет активен пункт меню `External linux-kernel local source settings`. Перейти в него и открыть пункт `EXternal  linux-kernel local source path`
		- далее ввести путь к исходникам ядра
			- можно использовать абсолютный путь
			- можно использовать путь с использованием переменной
				- `${TOPDIR}/../components/ext_sources/<MY-KERNEL>`
				- `${TOPDIR}/` указывает на директорию ` <plnx-proj-root>/build`
	- **желательно**,  чтобы исходники ядра находились в директории `<plnx-proj-root>/components/ext_sources/`
 - Сохранить конфигурацию `Save` и выйти из меню конфигурации `Exit`. После выхода из меню в консоли запустится процесс конфигурации.
	 - дождаться успешного завершения конфигурации ядра
### пакеты в rootfs
- Если требуется добавить или удалить **предустановленные пакеты** в `rootfs`, дать команду:
```bash
 petalinux-config -c rootfs
```
- Появится `menuconfig` и там можно выбрать нужные пакеты:
	- `ethtool`
	- `GDB server`
	- GDB
	- todo
 - Сохранить конфигурацию `Save` и выйти из меню конфигурации `Exit`. После выхода из меню в консоли запустится процесс конфигурации.
	 - дождаться успешного завершения конфигурации ядра
## сборка ядра
После завершения процесса конфигурации ядра  можно запустить сборку ядра Linux:
```bash
# перейти в корневую папку проекта
cd <Petalinux-project-folder>
petalinux-build
```
Запустится длительный процесс сборки ядра. Для дальнейшей работы требуется дождаться его завершения.
>в дальнейшем, вместо полной сборки ядра и компонентов, можно собирать компоненты отдельно. Для этого используется ключ `-c`.
>Например, для очистки и сборки компонента:
>`petalinux-build -c <component_name> -x do_cleansstate`
>`petalinux-build -c <component_name> -x do_install`
## сборка загрузочного образа
- перейти в директорию `images/linux/`
`cd <Petalinux-project-folder>/images/linux/`
- собрать загрузочные образы
```bash
petalinux-package --boot --fsbl zynqmp_fsbl.elf --fpga system.bit --u-boot --force
```
```bash
INFO: File in BOOT BIN: "/home/vivado/project/xilinx-zcu102-2018.3/images/linux/zynqmp_fsbl.elf"
INFO: File in BOOT BIN: "/home/vivado/project/xilinx-zcu102-2018.3/images/linux/pmufw.elf"
INFO: File in BOOT BIN: "/home/vivado/project/xilinx-zcu102-2018.3/images/linux/system.bit"
INFO: File in BOOT BIN: "/home/vivado/project/xilinx-zcu102-2018.3/images/linux/bl31.elf"
INFO: File in BOOT BIN: "/home/vivado/project/xilinx-zcu102-2018.3/images/linux/u-boot.elf"
INFO: Generating ZynqMP binary package BOOT.BIN...


****** Xilinx Bootgen v2018.3
  **** Build date : Nov 15 2018-19:22:29
    ** Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.

INFO: Binary is ready.

```
> **для ZCU102** файлы zynqmp_fsbl.elf и system.bit  можно использовать вместо fsbl.elf и  zcu102_top.bit из директории с файлами ПЛИС.
> Для **самодельных** плат нужно использовать `FSBL.elf` из директории собранной ПЛИС. `system.bit` из `images/linux` можно использовать вместо `.bit` файла из директории с собранной прошивкой ПЛИС.

- в результате в папке `linux` появятся файлы `BOOT.BIN image.ub` и файл `rootfs.tar.gz`
	- `BOOT.bin` и `image.ub` требуется скопировать на [[#форматирование SD карты|загрузочный]] раздел SD карты
	- `rootfs.tar.gz`  требуется распаковать на [[#форматирование SD карты|rootfs]] раздел SD карты
- карту памяти вставить в слот на плате
- ZCU102 выставить переключатель SW6 для загрузки с карты SD(1000)
## форматирование SD карты
Для загрузки карта памяти должна быть разбита на два раздела:
- загрузочный (boot)
	- свободное место 4мБ **перед** разделом
		- в ug1144 сказано, что начальный адрес раздела д.б. 4мб, т.е. старт первого раздела должен быть с сектора 8192. Но на практике плата не загружается. Если раздел начинается с сектора 2048, все проходит нормально
	- не менее 60 мБ
	- форматировать FAT32
	- метка `boot`
	- здесь будут файлы `BOOT.bin image.ub`
		- загрузчик, дерево устройств, образ ядра
- корневая фс (rootfs)
	- желательно выровнять на 4мБ
	- форматировать EXT4
	- метка `rootfs`
	- сюда **распаковать** архив `rootfs.tar.gz`
### создание разделов
С помощью `fdisk`:
- удалить старые разделы.
- создать раздел `boot`
	- создать `primary` раздел
	- номер раздела: `1`
	- номер стартового сектора: `2048`
	- номер последнего сектора: `+300М`
		- не менее 60МБ
		- размер раздела подобрать так, чтобы начало следующего раздела было выровнено на 4МБ
- создать раздел `rootfs`
	- создать `primary` раздел
	- номер раздела: `2`
	- номер стартового сектора: `212992`
	- номер последнего сектора: `по умолчанию`
- записать изменения на карту
```bash
Device     Boot  Start      End  Sectors  Size Id Type
/dev/sdc1         2048   616447   614400  300M 83 Linux
/dev/sdc2       616448 31116287 30499840 14,5G 83 Linux
```
### форматирование разделов
- форматировать раздел `boot`
```bash
sudo mkdosfs /dev/sdc1 -F 32
```
- форматировать раздел `rootfs`
```bash
sudo mkfs -t ext4 /dev/sdc2
```
### конфигурация tftp на petalinux
#### tftp server
если требуется, чтобы на плате работал tftp server, то нужно сконфигурить службу `tftpd`.
- в консоли дать команду `tftpd`. В ответ появится вывод:
```text
BusyBox v1.24.1 (2025-09-24 11:43:22 UTC) multi-call binary.

Usage: tftpd [-cr] [-u USER] [DIR]

Transfer a file on tftp client's request

tftpd should be used as an inetd service.
tftpd's line for inetd.conf:
        69 dgram udp nowait root tftpd tftpd -l /files/to/serve
It also can be ran from udpsvd:
        udpsvd -vE 0.0.0.0 69 tftpd /files/to/serve

        -r      Prohibit upload
        -c      Allow file creation via upload
        -u      Access files as USER
        -l      Log to syslog (inetd mode requires this)

```
 В подсказке указано, что в файл /etc/inetd.conf нужно добавить строку
`69 dgram udp nowait root tftpd tftpd -l /tftpboot`

- Добавляем строку в указанный файл. Например, командой
```bash
echo "69 dgram udp nowait root tftpd tftpd -l /tftpboot" >> /etc/inetd.conf
```
>`/tftpboot` - директория, с которой работает сервер. Можно изменить ее, например на `/srv/tftp` или оставить как есть.

> [!NOTE] Важно
> если `rootfs` располагается в ОЗУ (ramfs), настройка `tftpd` будет теряться после каждой перезагрузки платы. Чтобы настройка сохранялась, нужно [[#^46ca44|пересобрать]] ядро так, чтобы `rootfs` хранилась на карте памяти.
>

# детали
В директории контекста сборки во вложенной директории installer лежат файлы инсталлятора petalinux, файл bsp для платы и скрипт для автоматической установки petalinux. Для контроля там же лежат файлы с контрольными суммами перечисленных файлов.
# проблемы
## failed to source bitbake
Если при сборке проекта petalinux выводится эта ошибка, то посмотреть лог build.log и config.log в prj_dir/build
Если в логе ошибка:
```text
ERROR: No space left on device or exceeds fs.inotify.max_user_watches?
```

Ниже в логе даны рекомендации по исправлению ошибки:
```text
ERROR: To check max_user_watches: sysctl -n fs.inotify.max_user_watches.
ERROR: To modify max_user_watches: sysctl -n -w fs.inotify.max_user_watches=<value>

```
Проверка дает число 255, а если установить 122880, то начинает работать:
```bash
sysctl -n -w fs.inotify.max_user_watches=122880
```


