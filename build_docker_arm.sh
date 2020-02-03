#!/usr/bin/env bash


if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

helpFunction()
{
   echo ""
   echo "Usage: $0 [-n]"
   echo - "\t-i Install Docker 19.3 with ARM buildx"
   echo -e "\t-h Help"
   exit 1 # Exit script after printing help
}

INSTALL=0

while getopts "ih?" opt
do
   case "$opt" in
      i ) INSTALL=1 ;;
      h ) helpFunction ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done


if [ ${INSTALL}  -eq 1 ] ; then
  echo "#### Install Docker 19.3 ####"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic test"
  sudo apt-get update
  sudo curl -fsSL https://test.docker.com -o test-docker.sh
  sudo sh test-docker.sh
  sudo apt-get install qemu-user
  docker buildx rm armbuilder
  docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
  docker buildx create --name armbuilder --use


fi


usermod -a -G docker mperrocheau
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker buildx use armbuilder
docker buildx inspect --bootstrap


#docker login

##### for any info: https://community.arm.com/developer/tools-software/tools/b/tools-software-ides-blog/posts/getting-started-with-docker-for-arm-on-linux
#####
#####
#####
##### sudo cat ~/.docker/config.json should looks like:
#####
#{
#	"auths": {
#		"gitlab.teclib-erp.com": {
#			"auth": "bXBlcnJvY2*****IwOUAk"
#		},
#		"https://index.docker.io/v1/": {
#			"auth": "bXBlcnJvY2****zdGVyaWEx"
#		},
#		"registry.teclib-erp.com": {
#			"auth": "bXBlcnJvY2hl*****lMDIwOUAk"
#		}
#	},
#	"HttpHeaders": {
#		"User-Agent": "Docker-Client/19.03.5 (linux)"
#	},
#	"experimental": "enabled"
#}
#####
##### Error calling StartServiceByName for org.freedesktop.secrets
##### https://stackoverflow.com/questions/50151833/cannot-login-to-docker-account
##### or remove {
#    "credsStore": "xxxx"
#}
#
#
#
#

docker buildx build --platform "linux/arm/v7" -f ./print_rabbitmq_module/Dockerfile_arm  --push -t registry.teclib-erp.com/teclib/odoo-box:arm7 .
docker buildx build --platform "linux/arm/v7" -f ./flask_rpi/Dockerfile_arm  --push -t registry.teclib-erp.com/teclib/odoo-box:flask_rpi_arm7 .


