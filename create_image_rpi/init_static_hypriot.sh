#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

mknod -m 777 /dev/zero c 1 5
mknod -m 777 /dev/null c 1 3
chmod 777 /dev/null
chmod 777 /dev/zero
chown root:root /dev/null
chown root:root /dev/zero

df -h

apt-get update

ls -l /home/pi
ls -l /etc/ 
ls -l /etc/init.d

export LC_ALL="en_US.UTF-8"

# update-locale LANG=en_US.utf-8
cat /etc/default/locale

cat /etc/docker/daemon.json
cat /root/.docker/config.json

locale -a

apt-get install keyboard-configuration
#apt-get install cgroupfs-mount

# /etc/init.d/cloud-init start
# /etc/init.d/cloud-final start
#/etc/init.d/docker start
# /etc/init.d/raspi-config start

# cgroupfs-mount
# service containerd start
# service docker start

#dockerd
#systemctl status docker.service

# docker login gitlab.teclib-erp.com

#raspi-config