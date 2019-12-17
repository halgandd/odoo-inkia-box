HOST_NAME=odoo.inkia.fr
set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

# Since we are emulating, the real /boot is not mounted,
# leading to mismatch between kernel image and modules.
mount /dev/sda1 /boot
echo "************************************ dpkg --configure -a *************************************"
dpkg --configure -a
apt-get update
dpkg -P --force-all shared-mime-info
apt-get install shared-mime-info
apt-get dist-upgrade

# Recommends: antiword, graphviz, ghostscript, postgresql, python-gevent, poppler-utils
echo "************************************ nameserver 8.8.8.8 *************************************"
export DEBIAN_FRONTEND=noninteractive
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# Do not be too fast to upgrade to more recent firmware and kernel than 4.38
# Firmware 4.44 seems to prevent the LED mechanism from working

PKGS_TO_INSTALL="
    nginx-full \
    docker \
    printer-driver-all \
    libcups2-dev \
    pcscd \
    localepurge \
    vim \
    mc \
    mg \
    screen \
    iw \
    hostapd \
    git \
    rsync \
    swig \
    console-data \
    unclutter \
    x11-utils \
    openbox \
    rpi-update \
    adduser \
    python-cups \
    python3 \
    python3-serial \
    python3-pip \
    python3-dev \
    autossh \
    screen"

echo "Acquire::Retries "16";" > /etc/apt/apt.conf.d/99acquire-retries
# KEEP OWN CONFIG FILES DURING PACKAGE CONFIGURATION
# http://serverfault.com/questions/259226/automatically-keep-current-version-of-config-files-when-apt-get-install
apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install ${PKGS_TO_INSTALL}

echo "***************************************** apt-get clean *****************************************"

apt-get clean
localepurge
rm -rf /usr/share/doc

# python-usb in wheezy is too old
# the latest pyusb from pip does not work either, usb.core.find() never returns
# this may be fixed with libusb>2:1.0.11-1, but that's the most recent one in raspbian
# so we install the latest pyusb that works with this libusb.
# Even in stretch, we had an error with langid (but worked otherwise)
PIP_TO_INSTALL="
    pyusb==1.0.0b1 \
    evdev \
    gatt \
    v4l2 \
    pycups"
echo "************************************ install python library *************************************"

pip3 install ${PIP_TO_INSTALL}


groupadd usbusers
usermod -a -G usbusers pi
usermod -a -G lp pi
usermod -a -G input lightdm
mkdir /var/log/print_rabbitmq_module
chown pi:pi /var/log/print_rabbitmq_module
chown pi:pi -R /home/pi/print_rabbitmq_module/

echo "************************************ Install docker compose *************************************"
curl -sSL https://get.docker.com | sh
usermod -aG docker pi
pip3 install docker-compose

# logrotate is very picky when it comes to file permissions
chown -R root:root /etc/logrotate.d/
chmod -R 644 /etc/logrotate.d/
chown root:root /etc/logrotate.conf
chmod 644 /etc/logrotate.conf

echo "* * * * * rm /var/run/odoo/sessions/*" | crontab -

update-rc.d -f hostapd remove
update-rc.d -f nginx remove
update-rc.d -f dnsmasq remove
update-rc.d timesyncd defaults

systemctl daemon-reload
systemctl enable ramdisks.service
systemctl disable dphys-swapfile.service
systemctl enable ssh

# USER PI AUTO LOGIN (from nano raspi-config)
# We take the whole algorithm from raspi-config in order to stay compatible with raspbian infrastructure
if command -v systemctl > /dev/null && systemctl | grep -q '\-\.mount'; then
        SYSTEMD=1
elif [ -f /etc/init.d/cron ] && [ ! -h /etc/init.d/cron ]; then
        SYSTEMD=0
else
        echo "Unrecognised init system"
        return 1
fi
if [ $SYSTEMD -eq 1 ]; then
    systemctl set-default graphical.target
    ln -fs /etc/systemd/system/autologin@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
    rm /etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service
    rm /etc/systemd/system/hostapd.service
else
    update-rc.d lightdm enable 2
fi

# disable overscan in /boot/config.txt, we can't use
# overwrite_after_init because it's on a different device
# (/dev/mmcblk0p1) and we don't mount that afterwards.
# This option disables any black strips around the screen
# cf: https://www.raspberrypi.org/documentation/configuration/raspi-config.md
echo "disable_overscan=1" >> /boot/config.txt

# https://www.raspberrypi.org/forums/viewtopic.php?p=79249
# to not have "setting up console font and keymap" during boot take ages
setupcon


# create dirs for ramdisks
create_ramdisk_dir () {
    mkdir "${1}_ram"
}

create_ramdisk_dir "/var"
create_ramdisk_dir "/etc"
create_ramdisk_dir "/tmp"

echo "************************************ Configure ssh tennul *************************************"
while true; do
    read -p "Do you wish to configure ssh tennul?" yn
    case $yn in
        [Yy]* ) echo -e "\n\n\n" | ssh-keygen -t rsa;
              while true; do
                  read -p "Copy ssh key to remote server after tap Yes to continue esle No?" yn
                  case $yn in
                      [Yy]* ) mount -o remount,rw /dev/mmcblk0p2
                            mount -o remount,rw /root_bypass_ramdisks
                            echo 'pi:raspberry' | sudo chpasswd
                            echo 'raspberry@'${HOST_NAME} > /home/pi/.ssh/ssh_tunnel_user
                            echo '2222' > /home/pi/.ssh/ssh_tunnel_port
                            scp /home/pi/.ssh/id_rsa.pub `cat /home/pi/.ssh/ssh_tunnel_user`:.ssh/authorized_keys
                            scp `cat /home/pi/.ssh/ssh_tunnel_user`:.ssh/id_rsa.pub  /home/pi/.ssh/authorized_keys
                            line=""" * * * * * /usr/bin/screen -S reverse-ssh-tunnel -d -m autossh -M 65500 -i /home/pi/.ssh/id_rsa -o "ServerAliveInterval 20" -o "ServerAliveCountMax 3" -R `cat /home/pi/.ssh/ssh_tunnel_port`:localhost:22 `cat /home/pi/.ssh/ssh_tunnel_user` >/dev/null 2>&1"""
                            (crontab -u pi -l; echo "$line" ) | crontab -u pi -
                            cp /var/spool/cron/crontabs/pi /root_bypass_ramdisks/var/spool/cron/crontabs/
                            break;;
                      [Nn]* ) exit;;
                    * ) echo "Please answer yes or no.";;
                  esac
              done
              break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
mkdir /root_bypass_ramdisks
umount /dev/sda1

reboot
