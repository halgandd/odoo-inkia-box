#!/usr/bin/env bash

__dir=${1}

echo "############### MOUNT HYPRIOT IMAGE ################"
sleep 3
MOUNT_POINT="${__dir}/root_mount"
MOUNT_POINT_BOOT="${MOUNT_POINT}/boot"
LOOP=$(kpartx -avs hypriot_teclib.img)
LOOP_MAPPER_PATH=$(echo "${LOOP}" | tail -n 1 | awk '{print $3}')
LOOP_PATH="/dev/${LOOP_MAPPER_PATH::-2}"
LOOP_MAPPER_PATH="/dev/mapper/${LOOP_MAPPER_PATH}"
LOOP_MAPPER_BOOT=$(echo "${LOOP}" | tail -n 2 | awk 'NR==1 {print $3}')
LOOP_MAPPER_BOOT="/dev/mapper/${LOOP_MAPPER_BOOT}"
echo "${LOOP_MAPPER_PATH}" "${LOOP_MAPPER_BOOT}"



mount "${LOOP_MAPPER_PATH}" "${MOUNT_POINT}"
mount "${LOOP_MAPPER_BOOT}" "${MOUNT_POINT_ROOT}"
