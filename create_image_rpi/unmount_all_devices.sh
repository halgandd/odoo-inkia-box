#!/usr/bin/env bash

losetup
df -h
dmsetup -c info 

# HYP_IMG=$(losetup | grep hypriot | awk '{print $1}')
# echo "HYP_IMG= ${HYP_IMG}"

# if ! [ -z $HYP_IMG ]; then
#     echo "Unmount!"
#     losetup -d  ${HYP_IMG}
#     LOOP_NAME=$(basename "${HYP_IMG}")
#     echo "LOOP_NAME= ${LOOP_NAME}"
#     DEVICE_NAME=$(dmsetup -c info | grep "${LOOP_NAME}" | awk '{print $1}')
#     echo "DEVICE_NAME= ${DEVICE_NAME}"
#     dmsetup remove "${LOOP_NAME}p1"
#     dmsetup remove ${DEVICE_NAME}
# fi

# TEST_DIR="/media/myrrkel/boot"
# e2fsck -fp "${TEST_DIR}" # resize2fs requires clean fs
# resize2fs "${TEST_DIR}"




HYP_MOUNT_POINT=$(df -h | grep HypriotOS | awk '{print $1}')
HYP_MOUNT_PATH=$(df -h | grep HypriotOS | awk '{print $6}')

echo "HYP_MOUNT_POINT= ${HYP_MOUNT_POINT}"
echo "HYP_MOUNT_PATH= ${HYP_MOUNT_PATH}"

if ! [ -z $HYP_MOUNT_POINT ]; then
    echo "Unmount!"
    umount ${HYP_MOUNT_POINT}
fi


RASP_MOUNT_POINT=$(df -h | grep rasp | awk '{print $1}')
RASP_MOUNT_PATH=$(df -h | grep rasp | awk '{print $6}')

echo "RASP_MOUNT_POINT= ${RASP_MOUNT_POINT}"
echo "RASP_MOUNT_PATH= ${RASP_MOUNT_PATH}"

if ! [ -z $RASP_MOUNT_POINT ]; then
    echo "Unmount!"
    umount ${RASP_MOUNT_POINT}
fi




HYP_IMG=$(losetup | grep hypriot | awk '{print $1}')
echo "HYP_IMG= ${HYP_IMG}"

if ! [ -z $HYP_IMG ]; then
    echo "Unmount!"
    losetup -d  ${HYP_IMG}
    LOOP_NAME=$(basename "${HYP_IMG}")
    echo "LOOP_NAME= ${LOOP_NAME}"
    DEVICE_NAME=$(dmsetup -c info | grep "${LOOP_NAME}" | awk '{print $1}')
    echo "DEVICE_NAME= ${DEVICE_NAME}"
    dmsetup remove ${DEVICE_NAME}
fi


RASP_IMG=$(losetup | grep raspbian | awk '{print $1}')
echo "RASP_IMG= ${RASP_IMG}"

if ! [ -z $RASP_IMG ]; then
    echo "Unmount!"
    losetup -d  ${RASP_IMG}
    LOOP_NAME=$(basename "${RASP_IMG}")
    echo "LOOP_NAME= ${LOOP_NAME}"
    DEVICE_NAME=$(dmsetup -c info | grep "${LOOP_NAME}" | awk '{print $1}')
    echo "DEVICE_NAME= ${DEVICE_NAME}"
    dmsetup remove ${DEVICE_NAME}
fi

exit

