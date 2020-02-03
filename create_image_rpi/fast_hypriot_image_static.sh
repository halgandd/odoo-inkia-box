#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

helpFunction()
{
   echo ""
   echo "Usage: $0 [-n]"
   echo -e "\t-n No cleanup avoid to download several time the same files (debug mode)"
   echo -e "\t-e First boot with Qemu"
   echo -e "\t-h Help"
   exit 1 # Exit script after printing help
}

NOCLEANUP=0
BOOT_QEMU=0
while getopts "neh?" opt
do
   case "$opt" in
      n ) NOCLEANUP=1 ;;
      e ) BOOT_QEMU=1 ;;
      h ) helpFunction ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

file_exists() {
    [[ -f $1 ]];
}

require_command () {
    type "$1" &> /dev/null || { echo "Command $1 is missing. Install it e.g. with 'apt-get install $1'. Aborting." >&2; exit 1; }
}

require_command kpartx
require_command qemu-system-arm
require_command qemu-arm-static
require_command zerofree
require_command pv

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"losetup

LOCAL_TEMP="${__dir}/tmp"


cd "${__dir}"
if ! file_exists *hypriot*.img ; then
    ./raspberry_docker_download_images.sh
  else
      echo "HypriotOS Image found."
fi

if [ ! -f kernel-qemu ] ; then
    ./raspberry_docker_download_qemu.sh
  else
      echo "QEmu found."
fi

if [ ${NOCLEANUP}  -eq 0 ] ; then
    echo "Remove HypriotOS Teclib Image..."
    rm -f ./hypriot_teclib.img

    echo "Create HypriotOS Teclib Image..."
    pv *hypriot*.img > ./hypriot_teclib.img
fi


__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOUNT_POINT="${__dir}/root_mount"
MOUNT_POINT_BOOT="${MOUNT_POINT}/boot"
LOOP=$(kpartx -avs hypriot_teclib.img)
LOOP_MAPPER_PATH=$(echo "${LOOP}" | tail -n 1 | awk '{print $3}')
LOOP_PATH="/dev/${LOOP_MAPPER_PATH::-2}"
LOOP_MAPPER_PATH="/dev/mapper/${LOOP_MAPPER_PATH}"
LOOP_MAPPER_BOOT=$(echo "${LOOP}" | tail -n 2 | awk 'NR==1 {print $3}')
LOOP_MAPPER_BOOT="/dev/mapper/${LOOP_MAPPER_BOOT}"
echo "${LOOP_MAPPER_PATH}" "${LOOP_MAPPER_BOOT}"

if [ ${NOCLEANUP}  -eq 0 ] ; then
    echo "Enlarging the image..."
    dd if=/dev/zero bs=1M count=3000 status=progress >> hypriot_teclib.img
fi

echo "Fdisking: Resize partion table..."
START_OF_ROOT_PARTITION=$(fdisk -l hypriot_teclib.img | tail -n 1 | awk '{print $2}')
(echo 'p';                          # print
echo 'd';                          # delete
echo '2';                          #   second partition
echo 'n';                          # create new partition
echo 'p';                          #   primary
echo '2';                          #   number 2
echo "${START_OF_ROOT_PARTITION}"; #   starting at previous offset
echo '';                           #   ending at default (fdisk should propose max)
echo 'p';                          # print
echo 'w'; echo 'n') | fdisk hypriot_teclib.img       # write and quit

kpartx -u "${LOOP_MAPPER_PATH}"

e2fsck -fv "${LOOP_MAPPER_PATH}" # resize2fs requires clean fs
resize2fs "${LOOP_MAPPER_PATH}"
kpartx -u "${LOOP_MAPPER_PATH}"


# mkfs.ext4 -Fv "${LOOP_MAPPER_BOOT}" # format /boot file sytstem
# e2fsck -fv "${LOOP_MAPPER_BOOT}" 
# resize2fs "${LOOP_MAPPER_BOOT}" 

rm -R "${MOUNT_POINT}"
mkdir "${MOUNT_POINT}"
rm -R "${MOUNT_POINT_BOOT}"
mkdir "${MOUNT_POINT_BOOT}"
mount -v "${LOOP_MAPPER_PATH}" "${MOUNT_POINT}"
mount -v "${LOOP_MAPPER_BOOT}" "${MOUNT_POINT_BOOT}"
echo "MOUNT IMAGE..."
#resize2fs "${LOOP_MAPPER_PATH}"
# resize2fs "${LOOP_MAPPER_BOOT}"
#sleep 5
#./unmount_all_devices.sh
#./mount_hypriot_image.sh ""${__dir}"

#kpartx -u "${LOOP_MAPPER_PATH}"
#mount -o remount,rw "${LOOP_MAPPER_PATH}" "${MOUNT_POINT}"

#mkdir -p "${MOUNT_POINT}"/home/pi
#cp ./init_hypriot.sh "${MOUNT_POINT}"/etc/init.d/
#cp ./init_hypriot.sh "${MOUNT_POINT}"/home/pi/

#cp ./docker/config.json "${MOUNT_POINT}"/root/.docker/config.json
mkdir -p "${MOUNT_POINT}"/home/pi
cp ./init_static_hypriot.sh "${MOUNT_POINT}"/home/pi/
mkdir -p "${MOUNT_POINT}"/home/pi/docker
cp ./init_hypriot_docker.sh "${MOUNT_POINT}"/home/pi/
cp ./docker/*.tar "${MOUNT_POINT}"/home/pi/docker/
cp -r ../print_rabbitmq_module/config "${MOUNT_POINT}"/home/pi/
cp -f ./teclib_userdata.yml "${MOUNT_POINT_BOOT}/user-data"

if [ ${BOOT_QEMU}  -eq 1 ] ; then
#For Qemu
  cp ./90-qemu.rules "${MOUNT_POINT}"/etc/udev/rules.d/
  echo "#/usr/lib/arm-linux-gnueabihf/libarmmem.so" > "${MOUNT_POINT}"/etc/ld.so.preload
fi

echo "########### FILE: /etc/rc.local  ###################"
cat "${MOUNT_POINT}"/etc/rc.local


echo "########### BOOT ls  ###################"
ls -l "${MOUNT_POINT_BOOT}"

echo "########### FILE: boot/config.txt  ###################

cat "${MOUNT_POINT_BOOT}"/config.txt

echo "########### FILE: boot/cmdline.txt  ###################"
cat "${MOUNT_POINT_BOOT}"/cmdline.txt
cp "${MOUNT_POINT_BOOT}"/cmdline.txt ./
# echo "dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=PARTUUID=c73ba28a-02 rootfstype=ext4 cgroup_enable=cpuset cgroup_enable=memory swapaccount=1 elevator=deadline fsck.repair=yes rootwait quiet init=/usr/lib/raspi-config/init_resize.sh"
echo "dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=PARTUUID=c73ba28a-02 rootfstype=ext4 cgroup_enable=cpuset cgroup_enable=memory swapaccount=1 elevator=deadline rootwait quiet" > "${MOUNT_POINT_BOOT}"/cmdline.txt
sleep 1


echo "########### UNMOUNT ###################"
# umount -v "${MOUNT_POINT_BOOT}"
# umount -v "${LOOP_MAPPER_BOOT}"
# sleep 1
#umount -v "${MOUNT_POINT}"
# umount -v "${LOOP_MAPPER_PATH}"


# sleep 1
# kpartx -d hypriot_teclib.img
# ./unmount_all_devices.sh


# kpartx -avs hypriot_teclib.img
# mount -v "${LOOP_MAPPER_PATH}" "${MOUNT_POINT}"
#mount -o remount,rw "${MOUNT_POINT}"
# mount -o remount,rw "${MOUNT_POINT_BOOT}"
# partprobe
df -h
kpartx -u "${LOOP_MAPPER_PATH}"

QEMU_ARM_STATIC="/usr/bin/qemu-arm-static"
cp -v "${QEMU_ARM_STATIC}" "${MOUNT_POINT}/usr/bin/"
chroot "${MOUNT_POINT}" /bin/bash -c "/home/pi/init_static_hypriot.sh"
echo "#####   QEMU_ARM_STATIC COMPLETE #####"
sleep 1

if [ ${BOOT_QEMU}  -eq 1 ] ; then
  ./unmount_hypriot_image.sh -f

  QEMU_OPTS=(-kernel kernel-qemu -cpu arm1176 -m 256 -M versatilepb -dtb versatile-pb.dtb -no-reboot -serial stdio -append 'root=/dev/sda2 panic=1 rootfstype=ext4 rw' -hda hypriot_teclib.img -net user,hostfwd=tcp::10022-:22,hostfwd=tcp::18069-:8069 -net nic)
  echo "Starting Qemu..."
  qemu-system-arm "${QEMU_OPTS[@]}"
  sleep 1
  echo "#####   QEMU_SYSTEM_ARM COMPLETE #####"
fi


#flash --hostname inkia.teclib.local --userdata ./teclib_userdata.yml ./hypriot_teclib.img


sleep 1
umount "${LOOP_MAPPER_BOOT}"
umount "${LOOP_MAPPER_PATH}"


sleep 1

umount "${MOUNT_POINT_BOOT}"
umount "${MOUNT_POINT}"




sleep 1

# kpartx -dv "${LOOP_MAPPER_BOOT}"
# kpartx -dv "${LOOP_MAPPER_PATH}"

kpartx -d hypriot_teclib.img
e2fsck -f "${LOOP_MAPPER_PATH}" # resize2fs requires clean fs
./unmount_hypriot_image.sh -vf




# to connect to raspberry:
# ssh pirate@172.28.215.139
# password : hypriot

# sudo docker login registry.teclib-erp.com

#sudo docker pull hypriot/rpi-portainer
#sudo docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock hypriot/rpi-portainer


# Portainer: http://172.28.215.139:9000
# Cups: http://172.28.215.139:631/
# Flask: http://172.28.215.139:8050/
