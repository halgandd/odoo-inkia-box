#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

helpFunction()
{
   echo ""
   echo "Usage: $0 -u [UserName] -p [Password] -i [ImagePath]"
   echo -e "\t-v Verbose"
   echo -e "\t-f Force unmount image device"
   echo -e "\t-h Help"
   exit 1 # Exit script after printing help
}

VERBOSE=0
FORCE=0
while getopts "vfh?" opt
do
   case "$opt" in
      v ) VERBOSE=1 ;;
      f ) FORCE=1 ;;
      h ) helpFunction ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done


if [ ${VERBOSE} -eq 1 ] ; then
  echo "########### Docker Save Files #################"
fi

docker pull registry.teclib-erp.com/teclib/odoo-box:flask_rpi_arm7
docker pull registry.teclib-erp.com/teclib/odoo-box:arm7
docker pull lemariva/rpi-cups

mkdir -p ./docker
docker save -o ./docker/flask_rpi_arm7.tar registry.teclib-erp.com/teclib/odoo-box:flask_rpi_arm7
docker save -o ./docker/arm7.tar registry.teclib-erp.com/teclib/odoo-box:arm7
docker save -o ./docker/rpi-cups.tar lemariva/rpi-cups

