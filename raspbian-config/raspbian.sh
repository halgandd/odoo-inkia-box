#!/bin/bash
########################################################################################################################
# SUDO
########################################################################################################################
sudo su

########################################################################################################################
# LOCALE
########################################################################################################################
echo "************************************************************************************"
echo "Locale installation"
echo "************************************************************************************"
if [ "$(locale | grep LANG | cut -d= -f2)" != "fr_FR.UTF-8" ]; then
  echo "Install locale fr_FR.UTF8"
  raspi-config nonint do_change_locale fr_FR.UTF-8
  raspi-config nonint do_configure_keyboard fr
else
  echo "Locale is already fr_FR.UTF8"
fi

########################################################################################################################
# SSH
########################################################################################################################
mkdir -p /root/.ssh
touch /root/.ssh/known_hosts
mv /tmp/ssh/id_rsa /root/.ssh/
mv /tmp/ssh/id_rsa.pub /root/.ssh/
mv /tmp/ssh/gitlab-token /root/.ssh/
mv /tmp/ssh/gitlab-david-token /root/.ssh/
mv /tmp/ssh/gitlab-user /root/.ssh/
chown root:root /root/.ssh/id_rsa /root/.ssh/id_rsa.pub
if [ -f "/tmp/ssh/teclib-box.env" ]; then
  mv /tmp/ssh/teclib-box.env /root/.teclib-box.env
fi
rm -rf /tmp/ssh

########################################################################################################################
# PACKAGES
########################################################################################################################
echo "************************************************************************************"
echo "Package installation"
echo "************************************************************************************"
apt update -y
apt upgrade -y
apt install -y figlet vim git



# NGOK
echo "************************************************************************************"
echo "Ngok installation"
echo "************************************************************************************"
if ! [ -f "./ngrok.zip" ]; then
  curl 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip' > ngrok.zip
fi
if ! [ -f "./ngrok" ]; then
  unzip ngrok.zip
fi

# Docker
echo "************************************************************************************"
echo "Docker installation"
echo "************************************************************************************"
if ! [ -x "$(command -v docker)" ]; then
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  usermod -aG docker pi
else
  echo "Docker already installed"
fi

# Docker compose
echo "-----------------"
echo "Docker Compose installation"
echo "-----------------"
if ! [ -x "$(command -v docker-compose)" ]; then
  apt install -y python3-distutils python3-dev libffi-dev libssl-dev python3-pip
  pip3 install docker-compose
else
  echo "Docker Compose already installed"
fi

########################################################################################################################
# FILES
########################################################################################################################
echo "************************************************************************************"
echo "Copy files"
echo "************************************************************************************"
cp -r /tmp/datas/* /
rm -rf /tmp/datas
########################################################################################################################
# GIT
########################################################################################################################
echo "************************************************************************************"
echo "Clone repository"
echo "************************************************************************************"
if [ ! -n "$(grep "^gitlab.teclib-erp.com" ~/.ssh/known_hosts)" ]; then
  ssh-keyscan gitlab.teclib-erp.com >> ~/.ssh/known_hosts 2>/dev/null;
  ssh-keyscan registry.teclib-erp.com >> ~/.ssh/known_hosts 2>/dev/null;
fi

echo $(cat /root/.ssh/gitlab-david-token) | docker login -u dhalgand@teclib.com --password-stdin registry.teclib-erp.com
# TODO FIX
#echo $(cat /root/.ssh/gitlab-token) | docker login -u $(cat /root/.ssh/gitlab-user) --password-stdin registry.teclib-erp.com

if ! [ -d "/opt/teclib-box" ]; then
  git clone git@gitlab.teclib-erp.com:docker/teclib-box.git /opt/teclib-box
else
  cd /opt/teclib-box
  git pull
fi
./start.sh

########################################################################################################################
# RESTART
########################################################################################################################
echo "************************************************************************************"
echo "Reboot"
echo "************************************************************************************"
shutdown -r now
