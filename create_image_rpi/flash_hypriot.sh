#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi


get_raw_device_filename "$disk"
rawdisk=$_RET

echo "Flashing ${image} to ${rawdisk} ..."
if [[ -x $(command -v pv) ]]; then
  sudo_prompt
  size=$(/usr/bin/stat "$size_opt" "${image}")
  pv -s "${size}" < "${image}" | sudo dd bs=$bs_size "of=${rawdisk}"
else
  echo "No 'pv' command found, so no progress available."
  echo "Press CTRL+T if you want to see the current info of dd command."
  sudo dd bs=$bs_size "if=${image}" "of=${rawdisk}"
fi
