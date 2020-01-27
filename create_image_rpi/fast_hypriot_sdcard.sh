#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

file_exists() {
    [[ -f $1 ]];
}

require_command () {
    type "$1" &> /dev/null || { echo "Command $1 is missing. Install it e.g. with 'apt-get install $1'. Aborting." >&2; exit 1; }
}

rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"
  REPLY="${encoded}"
}

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


# echo "Remove HypriotOS Teclib Image..."
# rm -f ./hypriot_teclib.img

# echo "Create HypriotOS Teclib Image..."
# pv *hypriotos*.img > ./hypriot_teclib.img


flash --hostname inkia.teclib.local --userdata ./teclib_userdata.yml ./hypriot_teclib.img





