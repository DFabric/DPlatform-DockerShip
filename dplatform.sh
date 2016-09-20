#!/bin/sh
# DeployPlaform - Deploy self-hosted apps efficiently
# https://github.com/DFabric/DPlatform-ShellCore
# Copyright (c) 2015-2016 Julien Reichardt - MIT License (MIT)

# This script is implemented as POSIX-compliant.
# It should work on sh, dash, bash, ksh, zsh on Debian, Ubuntu, Fedora, CentOS
# and probably other distros of the same families, although no support is offered for them.

end="\33[0m"
# Blod red text color
cl="\33[0;37m"
# White selectioned color
sl="\33[1;31m"

get_key() {
  stty_state=$(stty -g)
  stty raw -echo min 1
  key=$(printf "$(dd bs=3 count=1 2>/dev/null)" | od -a)
  stty "$stty_state"
  key=${key#* *  }
  key=${key%*????????}
}

key_action() {
  case $key in
    w|W|' [   A') [ $linenb -gt 1 ] && linenb=$(( linenb - 1 )) || linenb=$total ;; # UP
    s|S|' [   B') [ $linenb -lt $total ] && linenb=$(( linenb + 1 )) || linenb=1;; # DOWN
    d|D|' [   C') ;; # RIGHT
    a|A|' [   D') ;; # LEFT
    q|Q|'0000000 esc') clear; exit;;
  esac
}

ssm() {
  linenb=1
  total="-1"
  printf "\033c$1\n"
  while read line ;do
    [ $total = 0 ] && printf "$3$sl$line$end\n" || printf "$3$cl$line$end\n"
    total=$(( total + 1 ))
  done <<EOT
  $(printf "$2\n")
EOT
  while get_key && [ "$key" != '0000000  cr' ]; do
    key_action
		printf "\033c$1\n"
    i=
    while read line ;do
      [ "$i" = $linenb ] && printf "$3$sl$line$end\n"  && lchoice=$line || printf "$3$cl$line$end\n"
      i=$(( i + 1 ))
    done <<EOT
    $(printf "$2")
EOT
  done
}

# DPlatform Docker

[ $(id -u) != 0 ] && printf "\033c\33[1;31m        You don't run this as root\33[0m
    You will need to have root permissions
    Press Enter <-'\n" && read null

# Current directory
[ "$DIR" = '' ] && DIR=$(cd -P $(dirname $0) && pwd)
cd $DIR

# Update
[ -d $DIR/.git ] && hash git 2>/dev/null && git pull

# Detect distribution
. /etc/os-release

# Detect package manager
if hash apt-get 2>/dev/null ;then
	PKG=deb
	install="debconf-apt-progress -- apt-get install -y"
	remove="apt-get purge -y"
elif hash dnf 2>/dev/null ;then
	PKG=rpm
	install="dnf install -y"
	remove="dnf remove -y"
elif hash yum 2>/dev/null ;then
	PKG=rpm
	install="yum install -y"
	remove="yum remove -y"
elif hash pacman 2>/dev/null ;then
	PKG=pkg
	install="pacman -Syu"
	remove="pacman -Rsy"
else
	echo Unknown operating system
fi

# Get the latest Docker package.
hash docker 2>/dev/null || { [ ! $ARCH = 86 ] && [ $ARCH != arm64 ] && { wget -qO- https://get.docker.com/ | sh || curl -sSL https://get.docker.com/ | sh; } || $install docker.io || $install docker; }

# Detect architecture
ARCH=$(arch)
case $ARCH in
	x86_64) ARCHf=x86; ARCH=amd64;;
	i*86) ARCHf=x86; ARCH=86;;
	aarch64) ARCHf=arm; ARCH=arm64;;
	armv7*) ARCHf=arm; ARCH=armv7;;
	armv6*) ARCHf=arm; ARCH=armv6;;
	*) printf "Your architecture $ARCH isn't supported\n"
esac

# Test if cuby responds
printf "Obtaining the IPv4 address from http://ip4.cuby-hebergs.com...\n"
IPv4=$(wget -qO- http://ip4.cuby-hebergs.com/ && sleep 1)
# Else use this site
[ "$IPv4" = "" ] && printf "Can't retrieve the IPv4 from cuby-hebergs.com.\nTrying to obtaining the IPv4 address from ipv4.icanhazip.com...\n" && IPv4=$(wget -qO- ipv4.icanhazip.com && sleep 1)
[ "$IPv4" = "" ] && printf ' /!\ WARNING - No Internet Connection /!\
You have no internet connection. You can do everything but install new containers\n'

IPv6=$(ip addr | sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d' | tail -n 2 | head -n 1)
[ $IPv6 = ::1 ] && IP=$IPv4 || IP=[$IPv6]

LOCALIP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)

wait_enter() {
  printf "Press \33[1;31mEnter <-'\33[0m to continue\n" && read null
}

port() {
	printf "\033c  	$APP port
	Set a port number for $APP
	Default: $1 "
	read port
	[ "$port" = "" ] && port=$1
}

network() {
	URL=
	printf "\033c	 $APP network access
	Leave blank to expose the service to the world
	For local network access only: $LOCALIP
	For local access only: localhost\n"
	read URL
	[ "$URL" != "" ] && URL=$URL:
}

secret() {
	printf "\033c	 $1 database secret
	Set a secret password for the $1 database\n"
	read secret
}

change_hostname() {
	printf "\033c\33[0;34m            Change your hostname\33[0m
	Your hostname must contain only ASCII letters 'a' through 'z' (case-insensitive),
	the digits '0' through '9', and the hyphen.
	Hostname labels cannot begin or end with a hyphen.
	No other symbols, punctuation characters, or blank spaces are permitted.
	Please enter a hostname (actual: $(hostname)):\n"
	read hostname
	if [ "$hostame" != "" ] ;then
		printf "$hostname\n" > /etc/hostname
		sed -i "s/ $($hostname) / $hostname /g" /etc/hosts
		ssm "You need to reboot to apply the hostname change." "  Reboot now?
    no
    yes"
		[ $lchoice = 2 ] && reboot
	fi
  menu
}

# Applications menus
install_menu() {

		# Installation menu
		ssm "                 DPlatform - Installation menu
		What container would you like to deploy? " "
		uifd/ui-for-docker | A pure client-side web interface for the Docker Remote API to connect and manage docker
		tobegit3hub/seagull | Friendly Web UI to manage and monitor docker
		rocket.chat | The Ultimate Open Source WebChat Platform
		ghost | Simple and powerful blogging/publishing platform
		wordpress | Create a beautiful website, blog, or app
		Redmine | Flexible project management web application
    Return to menu" "	"
    APP=${lchoice% |*}

    # Confirmation message
    [ "$APP" != "Return to menu" ] && ssm "		$APP will be installed." "Are you sure to want to continue?
    no
    yes" "	" || menu # Return to menu
    case $linenb in
      1) install_menu;; # Return to installation menu
      2)
        case $APP in
          uifd/ui-for-docker) port 9000; network
            docker run -d -p $URL$port:9000 --privileged -v /var/run/docker.sock:/var/run/docker.sock uifd/ui-for-docker;;

          tobegit3hub/seagull) port 10086; network
            docker run -d -p $URL$port:10086 -v /var/run/docker.sock:/var/run/docker.sock tobegit3hub/seagull;;

						rocket.chat) port 3000; network
						printf "\033c   Set your MongoDB instance URL
	If you have a MongoDB database, you can enter its URL and use it.
	You can also use a MongoDB service provider on the Internet.
	You can use a free https://mongolab.com/ database.
	Enter your Mongo URL instance (with the brackets removed)
	mongodb://:{user}:{password}@{host}:{port}/{datalink}
	>> BLANK to use a MongoDB container locally. <<\n"
	read MONGO_URL
							case "$MONGO_URL" in
								"") docker run --name db -d mongo:3 --smallfiles
									docker run --name rocketchat -p $port:3000 --env ROOT_URL=http://$URL --link db -d rocket.chat;;
								*) docker run --name rocketchat -p $port:3000 --env ROOT_URL=http://$URL --env MONGO_URL=$MONGO_URL -d rocket.chat;;
							esac;;

						ghost) port 8080
							docker run --name ghost-blog -p $port:2368 -d ghost;;

						wordpress) port 8080
							docker run --name wordpressdb -e MYSQL_ROOT_PASSWORD=$secret -e MYSQL_DATABASE=wordpress -d mariadb
							docker run --name wordpress --link wordpressdb:mysql -p $port:80 -d wordpress;;

						redmine)
							ssm "Redmine databse" "What database do you want to use?
							PostgreSQL | Recommened way
							MySQL | Recommended way
							SQlite3 | Simplest setup - One container. Not for multi-user production use"
							case $linenb in
								1) docker run -d --name redmine-postgres -e POSTGRES_PASSWORD=$secret -e POSTGRES_USER=redmine postgres
									docker run -d -p $port:3000 --name redmine --link redmine-postgres:postgres redmine;;
								2) docker run -d --name redmine-mysql -e MYSQL_ROOT_PASSWORD=$secret -e MYSQL_DATABASE=redmine mariadb
									docker run -d -p $port:3000 --name redmine --link redmine-mysql:mysql redmine;;
								3) docker run -d -p $port:3000 --name redmine redmine;;
							esac;;
					esac;;
			esac
      menu
}

# Docker Compose installation
docker_compose() {
	if [ $1 = install ] && ! hash docker-compose 2> /dev/null ;then
		printf "You have already docker-compose. Uninstall it first if you want to reinstall it again\n"
	elif [ $1 = install ] ;then
		ssm "Docker Compose"
		"How do you want to install docker-compose?
		Instakk from system package. Only included on recent systems
		Install from Official GitHub repository. Only for amd64 Linux, macOS and Windows
		Install the python pip package"
		case $linenb in
			1) # https://docs.docker.com/compose/install/
				ver=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/docker/compose/releases/latest)
				wget https://github.com/docker/compose/releases/download/$ver/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose || curl -L https://github.com/docker/compose/releases/download/$ver/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
				chmod +x /usr/local/bin/docker-compose;;
			2) $install docker-compose;;
			3) hash pip 2>/dev/null || $install pip
				pip install docker-compose;;
		esac
	elif [ $1 = update ] ;then
		$install docker-compose || rm /usr/local/bin/docker-compose || pip install docker-compose
	elif [ $1 = remove ] ;then
		$remove docker-compose || rm /usr/local/bin/docker-compose || pip uninstall docker-compose
	fi
}

# container manager menu
container_config(){

  ssm "\33[0;34m       $container_choice — $container_choice_name ($container_image) container setup\33[0m
  Running: $(docker inspect --format "{{ .State.Running }}" $container_choice)
  Auto-start at boot:" "
  Start/Stop the current $container_choice container process
	Udate container configuration - restart/cpu policy
	Backup the container with its volume data
	Delete the container with its volume data
	Status details about the current container
	Open a Bash shell to the container
  Return to menu" "    "
  container_action=$linenb
	case $container_action in

    1) ssm "$container_choice configuration update
      Select a configuration you would like to update" "
      Return to menu
      Start
      Restart
      Stop"
      case $linenb in
        1) ;;
        2) docker start $container_choice;;
        3) docker restart $container_choice;;
        4) docker stop $container_choice;;
      esac;;

		2) ssm "$container_choice configuration update
			Select a configuration you would like to update" "
      Return to menu
			Change the restart policy
			Limit container's cpu shares
			Update a custom container configuration"
			case $linenb in
        1) ;;
				2)
					ssm "$container_choice Select a configuration you would like to update" "
					no | Do not restart the container if it dies. (default)
					on-failure | Restart the container if it exits with a non-zero exit code
					always | Always restart the container no matter what exit code is returned
					unless-stopped | Change the restart policy" "	"
          restart_choice=${lchoice% |*}
					[ $restart_choice = on-failure ] && printf " --restart=on-failure\n You can also set an optional maximum restart count (e.g. on-failure:5)\n You can write an optional number" && read count && [ $count != "" ] && restart_choice=$restart_choice:$count
					[ $restart_choice != "" ] && docker update $container_choice --restart=$restart_choice && wait_enter;;
				3) printf "Available soon\n"; wait_enter;;
				4) printf "Available soon\n"; wait_enter;;
			esac;;

		3) docker export --message="$container_choice exported to $container_choice_name-bak.tar" $container_choice > $container_choice_name-bak.tar; wait_enter;;

		4) ssm "Remove $container_choice ($container_choice_name)
      $container_choice will be removed with its volumes" "Are you sure to want to continue?
      no
      yes" "  "
			[ $linenb = 2 ] && docker rm -f -v $container_choice && printf "$container_choice ($container_choice_name) removed with its volumes\n"
      wait_enter; container_manager;;

    5) printf "Available soon\n"; wait_enter;;

		6) docker exec -it $container_choice bash;;

    7) container_manager;; # Return to menu
  esac
  container_config

}

container_detection() {
	container_list="Docker global status"
	for container in $(docker ps -aq); do
		container_name=$(docker inspect --format='{{.Name}}' $container)
		container_name=${container_name#/}
    container_image=$(docker inspect --format='{{.Config.Image}}' $container)
    container_list="$container_list\n$container — $container_name ($container_image)"
	done
}

container_manager() {
	# Main Container Manager menu
  lchoice="Return to menu     "

  container_detection
  used_memory=$(free -m | awk '/Mem/ {printf "%.2g\n", (($3+$5)/1000)}')
  total_memory=$(free -m | awk '/Mem/ {printf "%.2g\n", ($2/1000)}')

  ssm "Container Manager
  Select with Arrows <-v-> and/or Tab <=>
  Memory usage: $used_memory GiB used / $total_memory GiB total" "
  Return to menu
  Import a container from a tarball
  $container_list"
  container_choice=${lchoice%% *}
  container_choice_name=$(docker inspect --format='{{.Name}}' $container_choice)
  [ "$container_choice" != "Return" ] || menu
  [ "$container_choice" = "Import" ] && printf "Write the path of your container tarball\n" && read path && docker import $path
  [ "$container_choice" = "Docker" ] && printf "\033c$(docker ps)\nPress Enter <-'\n" && read null && container_manager || container_config
  container_detection
}

cleanup() {
	ssm "\33[0;34m		Cleanup tools\33[0m" "
  Return to menu
	Orphaned volumes | Clean orphaned volumes not attached to any container
	Stopped containers | Delete all stopped containers with its related volumes" " "
	case $linenb in
    1) ;; # Return to menu
		2) docker volume rm $(docker volume ls -qf dangling=true); wait_enter;;
		3) docker rm -v $(docker ps -a -q);  wait_enter;;
	esac
  menu
}

menu() {
  # Main menu
  ssm "\33[0;34m		DPlatform - Main menu
  Select with arrows <-v-> and Tab <=>. Confirm with Enter <-'. Exit with Q/Esc
  Your can access to your apps by opening this address in your browser:
  \33[0m\33[1;35m		>| http://$(hostname)(:port) |<\33[0m" "
  Install | Install new containers
  Container Manager | Manage/remove containers (coming soon)
  Cleanup | Volume / container cleanup tools
  Hostname | Change the name of the server on your local network
  About | Informations about this project and your system
  Exit" "	"

  case $linenb in
    1) install_menu;;
  	2) container_manager;;
  	3) cleanup;;
  	4) change_hostname;;
  	5) printf "\033cDPlatform - Deploy self-hosted apps easily
      https://github.com/DFabric/DPlatform-DockerShip

  	- Domain/host name: `hostname`
  	- Local IPv4: $LOCALIP
  	- Public IPv4: $IPv4
  	- IPv6: $IPv6
  	Your OS: $ID $VERSION_ID $(uname -m)

  Copyright (c) 2016 Julien Reichardt - MIT License (MIT)

  Press Enter <-'\n"
  read null
  menu;;
    6) exit;; # Exit
  esac
}
menu
