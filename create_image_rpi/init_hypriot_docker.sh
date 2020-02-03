#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

if ! ( systemctl is-active --quiet docker ); then
  echo "Docker service is not active."
  exit
fi

file_exists() {
    [[ -f $1 ]];
}

docker_load() {
  if file_exists "${IMG_TAR}" ; then
    docker load -i "${1}"
    rm "${1}"
  fi
}

docker_load "/home/pi/docker/arm7.tar"
docker_load "/home/pi/docker/flask_rpi_arm7.tar"
docker_load "/home/pi/docker/rpi-cups.tar"
