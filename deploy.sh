#!/bin/bash

############################################################
#
#  Description : deploy docker containers for testing purposes
#
#  Author : Charles
#
###########################################################


# Functions #########################################################

help(){
echo "

Options :
		- --create : launch docker containers

		- --drop : remove docker containers created
	
		- --infos : show containers's attributes (ip, name, user...)

		- --start : restart docker containers

		- --ansible : create ansible template and set inventory according to new created containers

"

}

createNodes() {
	nb_machine=1
	[ "$1" != "" ] && nb_machine=$1
	min=1
	max=0

	idmax=`docker ps -a --format '{{ .Names}}' | awk -F "-" -v user="$USER" '$0 ~ user"-debian" {print $3}' | sort -r |head -1`
	min=$(($idmax + 1))
	max=$(($idmax + $nb_machine))

	# launch containers
	for i in $(seq $min $max);do
		docker build -t debian . 
		docker run -tid --privileged --publish-all=true -v /srv/data:/srv/html -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name $USER-debian-$i -h $USER-debian-$i -d debian
		docker exec -ti $USER-debian-$i /bin/sh -c "useradd -m -p sa3tHJ3/KuYvI $USER"
		docker exec -ti $USER-debian-$i /bin/sh -c "mkdir  ${HOME}/.ssh && chmod 700 ${HOME}/.ssh && chown $USER:$USER $HOME/.ssh"
	docker cp $HOME/.ssh/id_rsa.pub $USER-debian-$i:$HOME/.ssh/authorized_keys
	docker exec -ti $USER-debian-$i /bin/sh -c "chmod 600 ${HOME}/.ssh/authorized_keys && chown $USER:$USER $HOME/.ssh/authorized_keys"
		docker exec -ti $USER-debian-$i /bin/sh -c "echo '$USER   ALL=(ALL) NOPASSWD: ALL'>>/etc/sudoers"
		docker exec -ti $USER-debian-$i /bin/sh -c "service ssh start"
		echo "Container $USER-debian-$i created"
	done
	infosNodes	

}

dropNodes(){
	echo "Removing containers..."
	docker rm -f $(docker ps -a | grep $USER-debian | awk '{print $1}')
	echo "Remove completed"
}

startNodes(){
	echo ""
	docker start $(docker ps -a | grep $USER-debian | awk '{print $1}')
        for conteneur in $(docker ps -a | grep $USER-debian | awk '{print $1}');
	do
        	docker exec -ti $conteneur /bin/sh -c "service ssh start"
        done
	echo ""
}


createAnsible(){
	echo ""
  	ANSIBLE_DIR="ansible_dir"
  	sudo mkdir -p $ANSIBLE_DIR
  	sudo bash -c 'echo "all:" > ansible_dir/00_inventory.yml'
	sudo bash -c 'echo "  vars:" >> ansible_dir/00_inventory.yml'
        sudo bash -c 'echo "    ansible_python_interpreter: /usr/bin/python3" >> ansible_dir/00_inventory.yml'
        sudo bash -c 'echo "  hosts:" >> ansible_dir/00_inventory.yml'
	for conteneur in $(docker ps -a | grep $USER-debian | awk '{print $1}');
	do      
		ip_adress=`docker inspect -f "{{.NetworkSettings.IPAddress }}:" $conteneur`
		echo "    "$ip_adress | sudo tee -a ansible_dir/00_inventory.yml >> /dev/null
        	echo "host $conteneur => $ip_adress added to inventory" 
        done
        sudo mkdir -p $ANSIBLE_DIR/host_vars
        sudo mkdir -p $ANSIBLE_DIR/group_vars
	echo ""
}

infosNodes(){
	echo ""
	echo "Containers informations : "
	echo ""
	for conteneur in $(docker ps -a | grep $USER-debian | awk '{print $1}');do      
		docker inspect -f '   => {{.Name}} - {{.NetworkSettings.IPAddress }}' $conteneur
	done
	echo ""
}



# Script  ###################################################################""

if [ "$1" == "--create" ];then
	createNodes $2

elif [ "$1" == "--drop" ];then
	dropNodes

elif [ "$1" == "--start" ];then
	startNodes

elif [ "$1" == "--ansible" ];then
	createAnsible

elif [ "$1" == "--infos" ];then
	infosNodes

else
	help

fi




