#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

helpFunction()
{
   echo ""
   echo "Usage: $0 [-n]"
   echo -e "\t-n Don't recreate dockers images"
   echo -e "\t-h Help"
   exit 1 # Exit script after printing help
}

NOCLEANUP=0
GET_DOCKER_IMG=1
while getopts "ndh?" opt
do
   case "$opt" in
      n ) NOCLEANUP=1 ;;
      d ) GET_DOCKER_IMG=0 ;;

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
require_command zerofree
require_command pv

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"losetup

LOCAL_TEMP="${__dir}/tmp"


cd "${__dir}"
if ! file_exists *hypriotos*.img ; then
    ./raspberry_docker_download_images.sh
  else
      echo "HypriotOS Image found."
fi

if [ ! -f kernel-qemu ] ; then
    ./raspberry_docker_download_qemu.sh
  else
      echo "QEmu found."
fi

echo "Clean Up..."
./unmount_hypriot_image.sh -f

echo "Remove HypriotOS Teclib Image..."
rm -f ./hypriot_teclib.img

echo "Create HypriotOS Teclib Image..."
pv *hypriotos*.img > ./hypriot_teclib.img

if [ ${GET_DOCKER_IMG}  -eq 1 ] ; then
  echo "Create Docker images from local docker..."
  ./docker_save_images.sh
fi

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"


echo "Enlarging the image..."
dd if=/dev/zero bs=1M count=4000 status=progress >> hypriot_teclib.img
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
  echo 'w') | fdisk hypriot_teclib.img       # write and quit


MOUNT_POINT="${__dir}/root_mount"
MOUNT_POINT_ROOT="${MOUNT_POINT}/boot"
LOOP=$(kpartx -avs hypriot_teclib.img)
LOOP_MAPPER_PATH=$(echo "${LOOP}" | tail -n 1 | awk '{print $3}')
LOOP_PATH="/dev/${LOOP_MAPPER_PATH::-2}"
LOOP_MAPPER_PATH="/dev/mapper/${LOOP_MAPPER_PATH}"
LOOP_MAPPER_BOOT=$(echo "${LOOP}" | tail -n 2 | awk 'NR==1 {print $3}')
LOOP_MAPPER_BOOT="/dev/mapper/${LOOP_MAPPER_BOOT}"
echo "${LOOP_MAPPER_PATH}" "${LOOP_MAPPER_BOOT}"


rm -R "${MOUNT_POINT}"
mkdir "${MOUNT_POINT}"
mount "${LOOP_MAPPER_PATH}" "${MOUNT_POINT}"
mount "${LOOP_MAPPER_BOOT}" "${MOUNT_POINT_ROOT}"

e2fsck -f "${LOOP_MAPPER_PATH}" # resize2fs requires clean fs
resize2fs "${LOOP_MAPPER_PATH}"


echo "############ Image mounted! ###############"
#losetup
#df -h
#dmsetup -c info

mkdir -p "${MOUNT_POINT}"/home/pi
mkdir -p "${MOUNT_POINT}"/home/pi/docker
cp ./init_hypriot_docker.sh "${MOUNT_POINT}"/home/pi/
cp ./docker/*.tar "${MOUNT_POINT}"/home/pi/docker/
cp -r ../print_rabbitmq_module/config "${MOUNT_POINT}"/home/pi/
cp -f ./teclib_userdata.yml "${MOUNT_POINT_ROOT}/user-data"

#For Qemu
cp ./90-qemu.rules "${MOUNT_POINT}"/etc/udev/rules.d/
echo "#/usr/lib/arm-linux-gnueabihf/libarmmem.so" > "${MOUNT_POINT}"/etc/ld.so.preload


./unmount_hypriot_image.sh

sleep 1
kpartx -d hypriot_teclib.img
./unmount_hypriot_image.sh -f


QEMU_OPTS=(-kernel kernel-qemu -cpu arm1176 -m 256 -M versatilepb -dtb versatile-pb.dtb -no-reboot -serial stdio -append 'root=/dev/sda2 panic=1 rootfstype=ext4 rw' -hda hypriot_teclib.img -net user,hostfwd=tcp::10022-:22,hostfwd=tcp::18069-:8069 -net nic)

echo "Starting Qemu..."
qemu-system-arm "${QEMU_OPTS[@]}" | tee ./qemu.log


e2fsck -f "${LOOP_MAPPER_PATH}" # resize2fs requires clean fs


kpartx -d hypriot_teclib.img

cd "${__dir}"
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
