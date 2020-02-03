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
  echo "########### Hypriot Image Status #################"
  echo "########### losetup              #################"
  losetup
  echo "########### df -h                #################"
  df -h
  echo "########### dmsetup -c info      #################"
  dmsetup -c info

fi

echo "########### Unmount Hypriot Image #################"


LOOPS=$(df -h | grep root_mount | awk '{print $1}')
BOOT_LOOP=$(df -h | grep root_mount/boot | awk '{print $1}')
BOOT_MOUNT_PATH=$(df -h | grep /root_mount/boot | awk '{print $6}')

if [ ${VERBOSE} -eq 1 ] ; then
  echo "BOOT_LOOP= ${BOOT_LOOP}"
  echo "BOOT_MOUNT_PATH= ${BOOT_MOUNT_PATH}"
fi

if ! [ -z "$BOOT_LOOP" ]; then
    echo "########### Unmount ${BOOT_LOOP} ###########"
    umount ${BOOT_MOUNT_PATH}
    umount ${BOOT_LOOP}
fi

MOUNT_POINT=$(df -h | grep root_mount | awk '{print $1}')
MOUNT_PATH=$(df -h | grep /root_mount | awk '{print $6}')

if [ ${VERBOSE} -eq 1 ] ; then
  echo "MOUNT_POINT= ${MOUNT_POINT}"
  echo "MOUNT_PATH= ${MOUNT_PATH}"
fi

if ! [ -z "$MOUNT_POINT" ]; then
    echo "########### Unmount ${MOUNT_POINT} ###########"
    umount ${MOUNT_PATH}
    umount ${MOUNT_POINT}
fi



if [ ${FORCE} -eq 1 ] ; then
  echo "########### Unmount Hypriot File #################"

  IMG=$(losetup | grep hypriot | awk '{print $1}')
  FILE=$(losetup | grep hypriot | awk '{print $6}')

  if ! [ -z "$IMG" ]; then
      echo "Unmount Image: ${IMG} File: ${FILE}"
      losetup -d  ${IMG}
      LOOP_NAME=$(basename "${IMG}")
      echo "LOOP_NAME= ${LOOP_NAME}"
      DEVICE_NAME=$(dmsetup -c info | grep "${LOOP_NAME}" | awk '{print $1}')
      echo "DEVICE_NAME= ${DEVICE_NAME}"
      dmsetup remove "${DEVICE_NAME}"
  fi
fi


