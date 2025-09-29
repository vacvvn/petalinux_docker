 #!/bin/bash
# шаблон скрипта для запуска сборки компонента
# *************************************************** #
# ВАЖНО: НЕ РЕДАКТИРУЙТЕ НЕПОСРЕДСТВЕННО ЭТОТ ФАЙЛ, ПОТОМУ ЧТО ПРИ
# ПЕРЕЗАГРУЗКЕ КОНТЕЙНЕРА ИЗМЕНЕНИЯ БУДУТ ПОТЕРЯНЫ!
# перед началом работы требуется скопировать этот файл во внешнюю
# директорию /home/vivado/project и редактировать уже эту копию.
# *************************************************** #

# задать имя компонента для сборки
component_name="setName"
# задать тип компонента для сборки(modules; apps; bsp; core; kernel;)
component_type="modules"
# задать расширение файла бинарника компонента или пустую строку ""
component_ext=".ko"
# если исходники компонента содержатся вне проекта, то указать путь к исходникам,
# иначе оставить строку пустой: Src_dir="".
# Если строка непустая, скрипт скопирует содержимое директории в проект.
# КОМПОНЕНТ С ТАКИМ ЖЕ ИМЕНЕМ ДОЛЖЕН БЫТЬ УЖЕ СОЗДАН В ПРОЕКТЕ!
# Т.о. в начале надо создать компонент в проекте и скопировать его папку со всем
# содержимым  во внешнюю директорию(Src_dir). В дальнейшем редактировать
# исходники нужно уже во внешней директории, а скрипт скопирует их
# обратно в директорию проекта.
Src_dir="path/to/external/directory"
# куда скопировать бинарник компонента после сборки
# если не требуется, оставить пустым: target_dir=""
target_dir="/srv/tftp"
# куда архивировать исходники компонента после сборки
# если не требуется, оставить пустым: Arch_dir=""
Arch_dir="./"

#//////////////////////////
# эти переменные связаны с настройками Dockerfile
# образ докер
Image_name="petalinux:2018.3"
# директория установки petalinux(смотри Dockerfile)
pl_install_dir="/home/vivado/Xilinx/petalinux/2018.3"
# директория в контейнере, куда монтируется рабочая директория хоста
trg_prj_dir="/home/vivado/project"
# /////////////////////////
# эти переменные связаны с настройками petalinux
# имя проекта petalinux по умолчанию
Project_root_dir="./xilinx-zcu102-2018.3"
# здесь появятся исходники и артефакты сборки после выполнения цели do_install
# для каждого типа компонента свой адрес( подцепится автоматически)
# apps - aarch64-xilinx-linux
# modules - zcu102_zynqmp-xilinx-linux
Res_dir="zcu102_zynqmp-xilinx-linux"
#//////////////////////////


Cur_dir=`pwd`
echo -e "\nСборка компонента $component_name"
echo -e "Текущая директория: $Cur_dir"
echo -e "Директория проекта: " $Cur_dir/$Project_root_dir
if [[ ${#Src_dir} -gt 0 ]]; then
	# если исходники хранятся во внешней директории, то копируем их в проект
	echo -e "\nКопирую исходники $component_name в директорию $Project_root_dir"
	cp -R  $Src_dir/$component_name/* $Project_root_dir/project-spec/meta-user/recipes-$component_type/$component_name || exit 153
fi

# запускаем контейнер с командой очистки и сборки компонента
docker run -it --rm -w $trg_prj_dir/$Project_root_dir --mount type=bind,source=$Cur_dir,target=$trg_prj_dir $Image_name bash -c "source $pl_install_dir/main/settings.sh ; petalinux-build -c $component_name -x do_cleansstate; petalinux-build -c $component_name -x do_install" || exit 155
# создать архив проекта
if [[ ${#Arch_dir} -gt 0 ]]; then
	echo -e "Создание архивов $Arch_dir/$component_name.tar для отправки на тестирование"
	rm -f $Arch_dir/$component_name.tar
	tar cf $Arch_dir/$component_name.tar --directory $Project_root_dir/project-spec/meta-user/recipes-modules/$component_name .
fi
# скопировать бинарник в указанную директорию
if [[ ${#target_dir} -gt 0 ]]; then
	if [[ "$component_type" = "apps" ]]; then
		Res_dir = "aarch64-xilinx-linux"
	elif [[ "$component_type" = "modules" ]]; then
		Res_dir = "zcu102_zynqmp-xilinx-linux"
	else
		echo "Ошибка: Неизвестный тип компонента"
		exit 225
	fi
	echo -e "Копирую бинарный файл $component_name$component_ext в директорию $target_dir"
	cp -vf $Project_root_dir/build/tmp/work/$Res_dir/$component_name/1.0-r0/$component_name$component_ext $target_dir/
fi
echo -e "\n====== Сборка $component_name успешно завершена =========\n"

echo "Done"
date

