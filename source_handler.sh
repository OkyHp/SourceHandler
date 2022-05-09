#!/bin/bash
# Servers controls system by OkyHp (v1.2.0)
#######################################

# General handler dir name
general_dir='source_handler'

# Settings config file
settings_conf='settings.conf'

# Steam CMD dir name
logd_dir='logs'

# Start params config file
start_params_conf='start_params.conf'

# Backups config file
backup_conf='backup.conf'

# Backups dir name
backup_dir='backups'

# Steam CMD dir name
steam_cmd='steamcmd'

# Example settings config
example_settings_data=(
	"# --- HANDLER SETTINGS ---"
	""
	"# Time in minutes to delete logs older than this time"
	"handler_logs_time=\"4320\""
	""
	"# Time in minutes to delete backups older than this time"
	"handler_backups_time=\"43200\""
	""
	"# --- SERVER SETTINGS ---"
	""
	"# Server command executed when running command stop"
	"command_for_stop=\"sm_kick @all #SFUI_DisconnectReason_DisconnectedServerShuttingDown\""
	""
	"# Server command executed when running command restart"
	"command_for_restart=\"sm_kick @all Server restart! Retry connect after 1 min\""
	""
	"# Server command executed when running command update (-auto)"
	"command_for_update=\"sm_kick @all Server disabled for updating. Please wait few minutes\""
	""
	"# Server command executed when running command check-update (-update)"
	"command_for_cu=\"sm_kick @all Game update released! Update your game and connect back\""
)

# Example backup config
example_backup_data=(
	"../$start_params_conf"
	"../$backup_conf"
	"addons"
	"cfg/discord"
	"cfg/duel"
	"cfg/sourcemod"
	"cfg/vip"
	"cfg/autoexec.cfg"
	"cfg/banned_ip.cfg"
	"cfg/banned_user.cfg"
	"cfg/cvar_force.cfg"
	"cfg/gamemode_casual_server.cfg"
	"cfg/gamemode_competitive_server.cfg"
	"cfg/gotv.cfg"
	"cfg/performance.cfg"
	"cfg/server.cfg"
	"maps/aim_bfp"
	"maps/retakes_bfp"
	"maps/bhop_bfp"
	"maps/*.nav"
	"materials"
	"models"
	"particles"
	"sound"
	"token_auto_updater"
	"custom_mapcycle.txt"
	"custom_maplist.txt"
	"custom_motd.txt"
	"subscribed_collection_ids.txt"
	"subscribed_file_ids.txt"
	"*.png"
	"webapi_authkey.txt"
)

# NOT TOUCH THIS
#######################################

# Globals params
h_function=$1
h_server=$2
h_sub_function=$3

# Text color alias
RED='\033[0;31m' # Red
GREEN='\033[0;32m' # Green
YELLOW='\033[1;33m' # Yellow
NC='\033[0m' # Default

# Functions
message ()
{
	echo -e "$1";
}

openServerConsole () # 1:server
{
	cd ~/$1 && screen -x $1;
}

updateServer () # 1:steamcmd 2:server 3:validate
{
	if ! [ -e ~/$2 ]; then
		message ">> Сервер ${GREEN}$2 ${NC}не установлен!";
		die;
	fi

	if ! [ -e ~/$h_server/$start_params_conf ]; then
		message ">> ${RED}Ошибка! ${NC}Невозможно обновить сервер, без файла ${GREEN}$start_params_conf${NC}!";
		die;
	fi

	params='';
	if [ $3 -a $3 == "-val" ]; then
		params='validate';
		message ">> Используется параметр ${GREEN}validate${NC}.";
	fi

	message "\n";

	start_params=`cat ~/$h_server/$start_params_conf`;
	game=`echo "$start_params" | awk '/-game/{sub(/.*-game /, ""); print $1}'`;
	case $game in
		csgo)
			game_id='740'
		;;
		cstrike)
			game_id='232330'
		;;
		*)
			message ">> ${RED}Ошибка! ${NC}Игра '${GREEN}$game${NC}' не поддерживается!";
			die;
		;;
	esac

	message ">> Игра: ${GREEN}$game_id${NC}.";
	cd ~/$1 && ./steamcmd.sh +force_install_dir ~/$2/ +login anonymous +app_update $game_id $params +quit;
}

checkTwoArg ()
{
	if [ -z $1 ]; then
		message "\n\n>> ${RED}Ошибка! ${NC}Параметр ${GREEN}#2 ${NC}не указан!";
		die;
	fi
}

validServer ()
{
	if ! [ -e ~/$1 ]; then
		message "\n\n>> ${RED}Ошибка! ${NC}Сервер ${GREEN}$1 ${NC}не существует!";
		die;
	fi
}

printToLog ()
{
	echo "[$(date +"%d.%m.%y-%H:%M:%S")] $2" >> ~/$general_dir/$logd_dir/$1.log;
}

createDirectory ()
{
	if ! [ -d ~/$1 ]; then
		mkdir ~/$1;
		# message ">> ${GREEN}В корне пользователя создана директория '$1'${NC}";
	fi
}

loadSettingsConfig ()
{
	if [ -e ~/$general_dir/$settings_conf ]; then
		. ~/$general_dir/$settings_conf;
	else
		message "\n\n>> ${RED}Ошибка! ${NC}Инициализация не произведена!";
	fi
}

die ()
{
	message "\n=================================================================";
	cd ~/ && exit;
}

# Handler
#######################################

message "\n=================================================================\n";

case $h_function in
-console | -con)
	checkTwoArg $h_server;
	validServer $h_server;
	openServerConsole $h_server;
;;

-start)
	checkTwoArg $h_server;
	validServer $h_server;

	if [ -e ~/$h_server/$start_params_conf ]; then
		if [ -e /var/run/screen/S-$(whoami)/*.$h_server'_serv' ]; then
			message ">> ${RED}Ошибка! ${NC}Сервер ${GREEN}$h_server ${NC}уже запущен!";
			die;
		fi

		start_params=`cat ~/$h_server/$start_params_conf`; #$(head -n 1 $start_file);
		message ">> Запуск сервера ${GREEN}$h_server${NC}, ожидайте..";
		message "\n>> ${RED}Start Params${NC}: $start_params \n";

		cd ~/$h_server && screen -L -Logfile ~/$h_server/console.log -A -m -d -S $h_server'_serv' ./srcds_run $start_params;

		ip=`echo "$start_params" | awk '/ip/{sub(/.*[+|-]ip /, ""); print $1}'`;
		port=`echo "$start_params" | awk '/-port/{sub(/.*-port /, ""); print $1}'`;
		echo "${ip} ${port}" > ~/$h_server/cache;

		sleep 1;
		if [ $h_sub_function -a $h_sub_function = "-con" ]
		then
			openServerConsole $h_server;
		fi

		if [ -e /var/run/screen/S-$(whoami)/*.$h_server'_serv' ]; then
			message ">> Сервер ${GREEN}$h_server ${NC}запущен!";
			printToLog $h_server "[Start]: Server $h_server started.";
		else
			message ">> ${RED}Ошибка! ${NC}Сервер ${GREEN}$h_server ${NC}не запустился!";
		fi
	else
		message ">> ${RED}Ошибка! ${NC}Нет файла с параметрами запуска! ${NC}Создайте файл ${GREEN}$start_params_conf ${NC}в папке c сервером.";
	fi
;;

-stop)
	checkTwoArg $h_server;
	validServer $h_server;
	loadSettingsConfig;

	message ">> Выключение сервера ${GREEN}$h_server${NC}, ожидайте..";
	$0 -sc $h_server "$command_for_stop";

	if [ -e ~/$h_server/cache ]; then
		rm -f ~/$h_server/cache;
	fi

	cd ~/$general_dir/$steam_cmd && ./steamcmd.sh +quit;
	screen -X -S $h_server'_serv' quit;
	message "\n>> Сервер ${GREEN}$h_server ${NC}выключен!";
	printToLog $h_server "[Stop]: Server $h_server stopped.";
;;

-restart)
	if ! [ -e /var/run/screen/S-$(whoami)/*.$h_server'_serv' ]; then
		message ">> ${RED}Ошибка! ${NC}Сервер ${GREEN}$h_server ${NC}выключен!";
		die;
	fi

	loadSettingsConfig;
	cd ~/ && $0 -sc $h_server "$command_for_restart" && $0 -stop $h_server && $0 -start $h_server;
;;

-update)
	checkTwoArg $h_server;
	validServer $h_server;

	if ! [ -e ~/$h_server ]; then
		message ">> ${RED}Ошибка! ${NC}Сервер ${GREEN}$h_server ${NC}не установлен!";
		die;
	fi

	message ">> Процесс обновления сервера ${GREEN}$h_server ${NC}запущен..";

	if [ $h_sub_function -a $h_sub_function == "-auto" ]; then
		loadSettingsConfig;

		cd ~/;
		$0 -sc $h_server "$command_for_update";
		$0 -stop $h_server && $0 -update $h_server && $0 -start $h_server;
		message ">> Авто-обновление для ${GREEN}$h_server ${NC}завершено!";
		die;
	fi

	updateServer $general_dir/$steam_cmd $h_server $h_sub_function;
	message ">> Обновление ${GREEN}$h_server ${NC}завершено!";
	printToLog $h_server "[Update]: Server $h_server updated.";
;;

-list | -ls)
	# screen -ls;

	cur_user="/var/run/screen/S-$(whoami)/";
	if ! [ -d $cur_user ] || [ -z "$(ls -A $cur_user)" ]; then
		message ">> Нет активных серверов!";
		die;
	fi

	message ">> Список активных серверов:";

	cd $cur_user;
	for file in *; do
		message ">> - ${GREEN}$file${NC} [ $(date -r $cur_user$file "+%d.%m.%y %H-%M-%S") ]";
	done
;;

-check-update | -cu)
	checkTwoArg $h_server;
	validServer $h_server;

	printToLog $h_server "[Check update]: Checked update for server.";

	patch_version='';
	app_id='';
	while read line; do
		if [ "$(echo $line | grep -v "^#")" != "" ]; then
			IFS=’=’ read -ra params <<< "$line";
			if [ "${params[0]}" == "PatchVersion" ]; then
				patch_version="${params[1]}";
			fi
			if [ "${params[0]}" == "appID" ]; then
				app_id="${params[1]}";
			fi
		fi
	done < ~/$h_server/*/steam.inf

	message ">> Запрос на проверку обновления для ${GREEN}$h_server ${NC}сервера отправлена, ожидайте..\n";

	url="https://api.steampowered.com/ISteamApps/UpToDateCheck/v0001/?format=json&appid=$app_id&version=$patch_version";
	url="${url//[$'\t\r\n ']}";
	q_result=$(curl -i -H "Accept: application/json" -X GET $url);
	q_result="${q_result##*$'\n'}";
	read q_result < <(echo $q_result | jq -r '.response.required_version');

	if [ $q_result != "null" ]; then
		message "\n>> ${RED}Внимание, версия вашего сервера устарела!${NC} <<";
		message "\tАктуальная версия сервера: ${GREEN}$q_result${NC}";
		message "\tВерсия вашего сервера: ${RED}$patch_version${NC}";

		if [ $h_sub_function -a $h_sub_function == "-update" ]; then
			loadSettingsConfig;

			cd ~/;
			$0 -sc $h_server "$command_for_cu";
			$0 -update $h_server -auto;
		fi
	else
		message "\n>> Ваш сервер обновлен до актуальной версии: ${GREEN}$patch_version${NC}";
	fi
;;

-send-command | -sc)
	checkTwoArg $h_server;
	validServer $h_server;

	if [ -e /var/run/screen/S-$(whoami)/*.$h_server'_serv' ]; then
		message ">> На сервер ${GREEN}$h_server ${NC}отправлена команда ${GREEN}$h_sub_function${NC}.";
		screen -S $h_server'_serv' -p0 -X stuff "$h_sub_function"; # "$h_sub_function^M"
		screen -r $h_server'_serv' -p0 -X eval "stuff \015";

		if [ $4 -a $4 == "-return" ]; then
			sleep 1;
			screen -r $h_server'_serv' -p0 -X hardcopy $(tty);
			message ">> Выше возвращен ответ на запрос ${GREEN}$h_sub_function${NC}.";
		fi
	fi
;;

-clean-logs | -cll)
	checkTwoArg $h_server;
	validServer $h_server;

	if ! [ -e ~/$h_server/$start_params_conf ]; then
		message ">> ${RED}Ошибка! ${NC}Невозможно удалить логи, без файла ${GREEN}$start_params_conf${NC}!";
		die;
	fi

	loadSettingsConfig;

	start_params=`cat ~/$h_server/$start_params_conf`;
	game=`echo "$start_params" | awk '/-game/{sub(/.*-game /, ""); print $1}'`;

	find ~/$h_server/$game -type f -name '*.log' -mmin +$handler_logs_time -exec rm -f {} \;
	find ~/$h_server -type f -name 'console.log' -exec rm -f {} \;
	message ">> Все логи для ${GREEN}$h_server ${NC}удалены!";
	printToLog $h_server "[Clean logs]: Logs cleaned for $h_server server.";
;;

-backup)
	checkTwoArg $h_server;
	validServer $h_server;

	if ! [ -e ~/$h_server/$start_params_conf ]; then
		message ">> ${RED}Ошибка! ${NC}Невозможно создать бэкап сервера, без файла ${GREEN}$start_params_conf${NC}!";
		die;
	fi

	loadSettingsConfig;
	
	start_params=`cat ~/$h_server/$start_params_conf`;
	game=`echo "$start_params" | awk '/-game/{sub(/.*-game /, ""); print $1}'`;

	if ! [ -d ~/$general_dir/$backup_dir ]; then
		message ">> ${GREEN}В корне пользователя создана директория '$general_dir/$backup_dir'${NC}";
		mkdir ~/$general_dir/$backup_dir;
	else
		message ">> Удаление бэкапов старше ${GREEN}30 ${NC}дней, ожидайте..";
		find ~/$general_dir/$backup_dir -type f -name 'backup_*.zip' -mmin +$handler_backups_time -exec rm -f {} \;
	fi

	message "\n>> Создание бэкапа для ${GREEN}$h_server${NC}, ожидайте..";
	archive="backup_${h_server}_$(date +"%d.%m.%y_%H-%M-%S").zip";

	server_dir=~/$h_server/$game;
	cd $server_dir;
	while read data; do
		if [ -e $server_dir/$data ]; then
			zip -rv ~/$general_dir/$backup_dir/$archive $data;
		else
			message ">> ${RED}'${GREEN}$server_dir/$data${RED}' не найден или не существует, игнорирование!${NC}";
		fi
	done < ~/$h_server/$backup_conf

	#mv ~/$archive ~/!backups/;
	message ">> Бэкап для сервера ${GREEN}$h_server ${NC}создан!";
	printToLog $h_server "[Backup]: Backup created for $h_server server.";
;;

-install)
	checkTwoArg $h_server;

	if ! [ -e ~/$general_dir/$steam_cmd ]; then
		message ">> Процесс установки ${GREEN}SteamCMD ${NC}запущен, ожидайте..";
		mkdir ~/$general_dir/$steam_cmd && cd ~/$general_dir/$steam_cmd;
		wget http://media.steampowered.com/client/steamcmd_linux.tar.gz && tar xvfz steamcmd_linux.tar.gz;
		rm -f steamcmd_linux.tar.gz;
		message ">> Установка ${GREEN}SteamCMD ${NC}завершена!";
	fi

	if [ -e ~/$h_server/$start_params_conf ]; then
		message ">> ${RED}Ошибка! ${NC}Сервер ${GREEN}$h_server ${NC}уже установлен!";
		die;
	fi

	read server_ip < <(hostname -I);

	case $h_sub_function in
		-csgo)
			game_id='740'
			game_name='CS:GO'
			game_params="-game csgo \ \n-console \ \n-debug \ \n-nobots \ \n-usercon \ \n-port 27015 \ \n+clientport 37015 \ \n+net_public_adr $server_ip \ \n-ip $server_ip \ \n+game_type 0 \ \n+game_mode 0 \ \n-tickrate 128 \ \n-maxplayers_override 20 \ \n+map de_mirage \ \n+tv_port 47015 \ \n+tv_maxclients 0 \ \n-secure \ \n+sv_lan 0 \ \n+sv_setsteamaccount ?"
		;;
		-css)
			game_id='232330'
			game_name='CS:Source'
			game_params="-game cstrike \ \n-console \ \n-debug \ \n-nobots \ \n-usercon \ \n-port 27015 \ \n+clientport 37015 \ \n+net_public_adr $server_ip \ \n-ip $server_ip \ \n+game_type 0 \ \n+game_mode 0 \ \n-maxplayers 24 \ \n+map de_dust2 \ \n+tv_port 47015 \ \n+tv_maxclients 0 \ \n-secure \ \n+sv_lan 0"
		;;
		*)
			message ">> ${RED}Ошибка! ${NC}Не указан сервер для установки!";
			die;
		;;
	esac

	message ">> Процесс установки ${GREEN}сервера $game_name ${NC}запущен, ожидайте..";
	mkdir ~/$h_server;
	
	if ! [ -e ~/$h_server/$backup_conf ]; then
		printf "%s\n" "${example_backup_data[@]}" > ~/$h_server/$backup_conf;
	fi
	
	cd ~/$general_dir/$steam_cmd && ./steamcmd.sh +force_install_dir ~/$h_server/ +login anonymous +app_update $game_id validate +quit;
	message ">> Установка ${GREEN}сервера $game_name ${NC}завершена!";

	echo -e $game_params > ~/$h_server/$start_params_conf;
	chmod -R 700 ~/$h_server/$start_params_conf;

	message ">> Сгенерирован конфиг параметров запуска в '${GREEN}$(whoami)/$h_server/$start_params_conf${NC}'. Отредактируйте его! \nВнимание, соблюдайте форматирование!";
	printToLog $h_server "[Install]: Server $h_server ($game_id) installed.";
;;

-install-package | -i-p)
	if [[ $EUID -ne 0 ]]; then
		message ">> ${RED}Ошибка! ${NC}Пакеты могут быть установлены только с под sudo!";
		die;
	fi

	message ">> Процесс установки ${GREEN}стандартных пакетов ${NC}запущен, ожидайте..\n";
	sudo apt-get update;
	sudo apt-get -y install htop;
	sudo apt-get -y install screen;
	sudo apt-get -y install nano;
	sudo apt-get -y install zip;
	sudo apt-get -y install cron;
	sudo apt-get -y install curl;
	sudo apt-get -y install jq;
	sudo apt-get -y install wget;
	sudo apt-get -y install dpkg;

	sudo apt-get -y install lib32gcc1;
	sudo apt-get -y install lib32stdc++6;
	sudo apt-get -y install lib32z1;
	sudo apt-get -y install libcurl3;
	sudo apt-get -y install gawk;
	sudo apt-get -y install gdb;

	sudo wget http://ftp.de.debian.org/debian/pool/main/n/ncurses/lib32tinfo5_6.0+20161126-1+deb9u2_amd64.deb;
	sudo dpkg -i lib32tinfo5_6.0+20161126-1+deb9u2_amd64.deb;
;;

-init)
	cd ~/;
	createDirectory $general_dir
	createDirectory $general_dir/$logd_dir;
	createDirectory $general_dir/$backup_dir;

	if ! [ -e $general_dir/$settings_conf ]; then
		printf "%s\n" "${example_settings_data[@]}" > $general_dir/$settings_conf;
	fi

	checkTwoArg $2;
	ln -s $0 ~/$2;
	message ">> Инициализация завершена, использование скрипта: ./$2 -help!";
;;

-monitor)
	checkTwoArg $h_server;
	validServer $h_server;

	if ! [ -e /var/run/screen/S-$(whoami)/*.$h_server'_serv' ]; then
		message ">> ${RED}Ошибка! ${NC}Сервер ${GREEN}$h_server ${NC}выключен!";
		die;
	fi

	printToLog $h_server "[Monitor]: Checked server state.";

	s_file=`cat ~/$h_server/cache`;
	ip=`echo "$s_file" | awk '{print $1}'`;
	port=`echo "$s_file" | awk '{print $2}'`;
	message ">> Отправка запроса на ${GREEN}$h_server ($ip:$port)${NC}, ожидайте..";

	lost="0";
	while [ "$lost" != "10"  ]
	do
		bash -c "exec 3<>/dev/tcp/${ip}/${port}";
		if [ "$?" == "0" ]; then
			message "\n>> Запрос ${GREEN}успешно ${NC}отправлен!";
			die;
		else
			lost=$((lost + 1));
			message "\n>> ${RED}Ошибка ${NC}при отправлении запроса! ($lost / 10)";
			sleep 3;
		fi
	done

	if [ "$lost" == "10" ]; then
		printToLog $h_server "[Monitor]: Connection fail to server, restart!";
		$0 -restart $h_server;
	fi
;;

-create-cron | -cc)
	checkTwoArg $h_server;
	validServer $h_server;

	message ">> Сгенерированная настройка CRON для сервера ${GREEN}$h_server${NC}:\n\n";

	path="`pwd`${0:1:${#0}}";
	message "${GREEN}# Check update for server \n30 * * * * $path -cu $h_server -update\n${NC}";
	message "${GREEN}# Check server availability \n*/15 * * * * $path -monitor $h_server\n${NC}";
	message "${GREEN}# Clean server logs \n30 4 * * * $path -cll $h_server\n${NC}";
	message "${GREEN}# Auto restart and update server \n35 4 * * * $path -update $h_server -auto\n${NC}";
	message "${GREEN}# Create server backup \n0 4 * * 2 $path -backup $h_server\n${NC}";
	message "${GREEN}# Auto server start after reboot \n@reboot $path -start $h_server >> ~/$general_dir/$logd_dir/start.log 2>&1${NC}";
;;

-ac)
	message ">> Смена прав для домашней директории рекурсивно";
	chmod -R 700 ~/;
;;

-help | -h)
	message "Использование: ${GREEN}$0 <command> <server/agr #2> <agr #3> ...\n";
	message "${NC}Команды(Ключи): ";
	message "\n-----------------------------------------------------------------\n";
	message " ${GREEN}-init \t\t\t\t${NC}| Инициализация среды для скрипта. Cоздание всех конфигов и ярлыка для работы с скриптом (обработчиком).";
	message " ${GREEN}-install-package ${NC}или ${GREEN}-i-p \t${NC}| Установить стандартные пакеты для работы сервера.";
	message " ${GREEN}-install \t\t\t${NC}| Установить новый сервер. Имеет #3 аргумент: \n\t\t\t\t|\t${GREEN}-csgo ${NC}-- Установит CS:GO сервер. \n\t\t\t\t|\t${GREEN}-css ${NC}-- Установит CS:Source сервер.";
	message "\n-----------------------------------------------------------------\n";
	message " ${GREEN}-list \t\t  ${NC}или ${GREEN}-ls \t${NC}| Просмотреть активные серверы.";
	message " ${GREEN}-start \t\t\t${NC}| Включение сервера. Имеет #3 аргумент: \n\t\t\t\t|\t${GREEN}-con ${NC}-- Откроет консоль сервера при запуске.";
	message " ${GREEN}-stop	 \t\t\t${NC}| Выключение сервера";
	message " ${GREEN}-restart \t\t\t${NC}| Перезапуск сервера";
	message " ${GREEN}-update \t\t\t${NC}| Обновление сервера. Имеет #3 аргумент: \n\t\t\t\t|\t${GREEN}-val ${NC}-- Запустит validate update. \n\t\t\t\t|\t${GREEN}-auto ${NC}-- Выключает, обновляет и запускает сервер (Для Cron).";
	message " ${GREEN}-console \t  ${NC}или ${GREEN}-con \t${NC}| Открыть консоль сервера.";
	message " ${GREEN}-check-update \t  ${NC}или ${GREEN}-cu \t${NC}| Проверить наличие обновления для сервера. Имеет #3 аргумент: \n\t\t\t\t|\t${GREEN}-update ${NC}-- Если обновление найдено - обновить сервер.";
	message " ${GREEN}-monitor \t\t\t${NC}| Проверить доступность сервера из сети через TCP запрос.";
	message " ${GREEN}-clean-logs \t  ${NC}или ${GREEN}-cll \t${NC}| Очистка всех логов в директории сервера.";
	message " ${GREEN}-send-command \t  ${NC}или ${GREEN}-sc\t${NC}| Отправить команду на сервер. Имеет #4 аргумент: \n\t\t\t\t|\t${GREEN}-return ${NC}-- Вернет выхлоп отправленной команды.";
	message " ${GREEN}-backup \t\t\t${NC}| Создать бэкап для сервера.";
	message " ${GREEN}-create-cron \t  ${NC}или ${GREEN}-cc \t${NC}| Сгенерировать настройку CRON для сервера.";
	# message "\n-----------------------------------------------------------------\n";
;;

*)
	message ">> ${RED}Ошибка! ${NC}Неверная команда! Введите ${GREEN}-help ${NC}или ${GREEN}-h${NC}.";
;;
esac

die;
