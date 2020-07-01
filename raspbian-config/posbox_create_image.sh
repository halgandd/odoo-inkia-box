#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

new_image=0
########################################################################################################################
# PARAMETERS
########################################################################################################################
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

########################################################################################################################
# CHECK COMMAND
########################################################################################################################
file_exists() {
    [[ -f $1 ]];
}

require_command () {
    type "$1" &> /dev/null || { echo "Command $1 is missing. Install it e.g. with 'apt-get install $1'. Aborting." >&2; exit 1; }
}

require_command kpartx
require_command qemu-arm-static
require_command zerofree

########################################################################################################################
# VARIABLES
########################################################################################################################
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"

MOUNT_POINT="${__dir}/root_mount"
OVERWRITE_FILES_BEFORE_INIT_DIR="${__dir}/overwrite_before_init"
OVERWRITE_FILES_AFTER_INIT_DIR="${__dir}/overwrite_after_init"
VERSION=13.0
VERSION_IOTBOX=20.02
REPO=https://github.com/odoo/odoo.git

########################################################################################################################
# BASE IMAGE
########################################################################################################################
#if ! file_exists *raspbian*.img ; then
#    echo ">>>>>>>> Download base the image..."
#    wget 'http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-07/2020-02-05-raspbian-buster-lite.zip' -O raspbian.img.zip
#    unzip raspbian.img.zip
#fi

RASPBIAN=2019-09-26-raspbian-buster-lite.img


########################################################################################################################
# CLONE
########################################################################################################################
CLONE_DIR="${OVERWRITE_FILES_BEFORE_INIT_DIR}/home/pi/odoo"

#rm -rfv "${CLONE_DIR}"
#
#if [ ! -d $CLONE_DIR ]; then
#    echo "Clone Github repo"
#    mkdir -pv "${CLONE_DIR}"
#    git clone -b ${VERSION} --no-local --no-checkout --depth 1 ${REPO} "${CLONE_DIR}"
#    cd "${CLONE_DIR}"
#    git config core.sparsecheckout true
#    echo "addons/web
#addons/hw_*
#addons/point_of_sale/tools/posbox/configuration
#odoo/
#odoo-bin" | tee --append .git/info/sparse-checkout > /dev/null
#    git read-tree -mu HEAD
#fi

########################################################################################################################
# NGROK
########################################################################################################################
#cd "${__dir}"
#USR_BIN="${OVERWRITE_FILES_BEFORE_INIT_DIR}/usr/bin/"
#mkdir -pv "${USR_BIN}"
#cd "/tmp"
#curl 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip' > ngrok.zip
#unzip ngrok.zip
#rm -v ngrok.zip
#cd "${__dir}"
#mv -v /tmp/ngrok "${USR_BIN}"

########################################################################################################################
# IMAGE RESIZE
########################################################################################################################
# zero pad the image to be around 4.4 GiB, by default the image is only ~2.2 GiB
#echo ">>>>>>>> Enlarging the image..."
if [[ $new_image -ne 0 ]]; then
  rsync -avh --progress "${RASPBIAN}" iotbox.img
  dd if=/dev/zero bs=1M count=2048 status=progress >> iotbox.img
fi

# resize partition table
echo ">>>>>>>> Fdisking"

echo ">>>>>>>> Calculate sector"
SECTORS_BOOT_START=$(sudo fdisk -l iotbox.img | tail -n 2 | awk 'NR==1 {print $2}')
SECTORS_BOOT_END=$((SECTORS_BOOT_START + 1048576)) # sectors to have a partition of ~512Mo
SECTORS_ROOT_START=$((SECTORS_BOOT_END + 1))

echo "SECTORS_BOOT_START $SECTORS_BOOT_START"
echo "SECTORS_BOOT_END $SECTORS_BOOT_END"
echo "SECTORS_ROOT_START $SECTORS_ROOT_START"

START_OF_ROOT_PARTITION=$(fdisk -l iotbox.img | tail -n 1 | awk '{print $2}')
(echo 'p';                          # print
 echo 'd';                          # delete
 echo '2';                          #    number 2
 echo 'd';                          # delete number 1 by default
 echo 'n';                          # create new partition
 echo 'p';                          #   primary
 echo '1';                          #   number 1
 echo "${SECTORS_BOOT_START}";      #   first sector
 echo "${SECTORS_BOOT_END}";        #   partition size
 echo 't';                          # change type of partition. 1 selected by default
 echo 'c';                          #   change to W95 FAT32 (LBA)
 echo 'n';                          # create new partition
 echo 'p';                          #   primary
 echo '2';                          #   number 2
 echo "${SECTORS_ROOT_START}";      #   starting at previous offset
 echo '';                           #   ending at default (fdisk should propose max)
 echo 'p';                          # print
 echo 'w') | fdisk iotbox.img       # write and quit

LOOP_RASPBIAN=$(kpartx -avs "${RASPBIAN}")
LOOP_RASPBIAN_ROOT=$(echo "${LOOP_RASPBIAN}" | tail -n 1 | awk '{print $3}')
LOOP_RASPBIAN_PATH="/dev/${LOOP_RASPBIAN_ROOT::-2}"
LOOP_RASPBIAN_ROOT="/dev/mapper/${LOOP_RASPBIAN_ROOT}"
LOOP_RASPBIAN_BOOT=$(echo "${LOOP_RASPBIAN}" | tail -n 2 | awk 'NR==1 {print $3}')
LOOP_RASPBIAN_BOOT="/dev/mapper/${LOOP_RASPBIAN_BOOT}"


echo "LOOP_RASPBIAN_PATH $LOOP_RASPBIAN_PATH"

LOOP_IOT=$(kpartx -avs iotbox.img)
LOOP_IOT_ROOT=$(echo "${LOOP_IOT}" | tail -n 1 | awk '{print $3}')
LOOP_IOT_PATH="/dev/${LOOP_IOT_ROOT::-2}"
LOOP_IOT_ROOT="/dev/mapper/${LOOP_IOT_ROOT}"
LOOP_IOT_BOOT=$(echo "${LOOP_IOT}" | tail -n 2 | awk 'NR==1 {print $3}')
LOOP_IOT_BOOT="/dev/mapper/${LOOP_IOT_BOOT}"

echo "LOOP_IOT_PATH $LOOP_IOT_PATH"

sleep 60
umount -fv "${LOOP_RASPBIAN_BOOT}"
umount -fv "${LOOP_RASPBIAN_ROOT}"
umount -fv "${LOOP_IOT_ROOT}"
umount -fv "${LOOP_IOT_BOOT}"

if [[ $new_image -ne 0 ]]; then
  mkfs.ext4 -v "${LOOP_IOT_ROOT}"
  dd if="${LOOP_RASPBIAN_ROOT}" of="${LOOP_IOT_ROOT}" bs=4M status=progress

  # resize filesystem
  e2fsck -fv "${LOOP_IOT_ROOT}" # resize2fs requires clean fs
  resize2fs "${LOOP_IOT_ROOT}"
fi

mkdir -pv "${MOUNT_POINT}" #-p: no error if existing
echo "mount -v ${LOOP_IOT_ROOT} ${MOUNT_POINT}"
mount -v "${LOOP_IOT_ROOT}" "${MOUNT_POINT}"
echo "mount -v ${LOOP_IOT_BOOT} ${MOUNT_POINT}/boot/"
mount -v "${LOOP_IOT_BOOT}" "${MOUNT_POINT}/boot/"

QEMU_ARM_STATIC="/usr/bin/qemu-arm-static"
cp -v "${QEMU_ARM_STATIC}" "${MOUNT_POINT}/usr/bin/"

########################################################################################################################
# COPY FILES
########################################################################################################################
# 'overlay' the overwrite directory onto the mounted image filesystem
#echo ">>>>>>>> copy files"
#cp -av "${OVERWRITE_FILES_BEFORE_INIT_DIR}"/* "${MOUNT_POINT}"
#chroot "${MOUNT_POINT}" /bin/bash -c "sudo /etc/init_posbox_image.sh"

########################################################################################################################
# COPY VERSION
########################################################################################################################
# copy iotbox version
echo ">>>>>>>> set version"
echo "${VERSION_IOTBOX}" > "${MOUNT_POINT}"/home/pi/iotbox_version

########################################################################################################################
# REMOVE CLONE
########################################################################################################################
# get rid of the git clone
echo ">>>>>>>> CLEAN rm local clone"
rm -rfv "${CLONE_DIR}"

########################################################################################################################
# REMOVE NGROK
########################################################################################################################
# and the ngrok usr/bin
echo ">>>>>>>> CLEAN rm local /usr"
rm -rfv "${OVERWRITE_FILES_BEFORE_INIT_DIR}/usr"

########################################################################################################################
# COPY FILES
########################################################################################################################
echo ">>>>>>>> COPY after init"
#cp -av "${OVERWRITE_FILES_AFTER_INIT_DIR}"/* "${MOUNT_POINT}"

########################################################################################################################
# PATCH
########################################################################################################################
echo ">>>>>>>> patch"
#find "${MOUNT_POINT}"/ -type f -name "*.iotpatch"|while read iotpatch; do
#    DIR=$(dirname "${iotpatch}")
#    BASE=$(basename "${iotpatch%.iotpatch}")
#    find "${DIR}" -type f -name "${BASE}" ! -name "*.iotpatch"|while read file; do
#        patch -f --verbose "${file}" < "${iotpatch}"
#    done
#done

########################################################################################################################
# CLEANUP
########################################################################################################################
echo ">>>>>>>> unmount"
umount -fv "${MOUNT_POINT}"/boot/
umount -fv "${MOUNT_POINT}"/
rm -rfv "${MOUNT_POINT}"

echo ">>>>>>>> running zerofree..."
zerofree -v "${LOOP_IOT_ROOT}" || true

sleep 10

echo ">>>>>>>> remove mount"
echo "LOOP_IOT_PATH $LOOP_IOT_PATH"
echo "LOOP_RASPBIAN_PATH $LOOP_RASPBIAN_PATH"
kpartx -dv "${LOOP_IOT_PATH}"
kpartx -dv "${LOOP_RASPBIAN_PATH}"
