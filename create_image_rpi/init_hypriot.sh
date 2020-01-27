#!/usr/bin/env bash
#set -o errexit
#set -o nounset
#set -o pipefail
#set -o keyword
# set -o xtrace
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

helpFunction()
{
   echo ""
   echo "Usage: $0 -u [UserName] -p [Password] -i [ImagePath]"
   echo -e "\t-u Teclib ERP Gitlab User Name"
   echo -e "\t-p Teclib ERP Gitlab Password"
   echo -e "\t-n No cleanup avoid to download several time the same files (debug mode)"
   echo -e "\t-g Use local odoo-box directory as source in ./tmp/local/ (debug mode)"
   echo -e "\t-h Help"
   exit 1 # Exit script after printing help
}

NOCLEANUP=0
GIT_LOCAL=0
while getopts "u:p:ngh?" opt
do
   case "$opt" in
      u ) GITLAB_USERNAME="$OPTARG" ;;
      p ) GITLAB_PASSWORD="$OPTARG" ;;
      n ) NOCLEANUP=1 ;;
      g ) GIT_LOCAL=1 ;;
      h ) helpFunction ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac


done

# Print helpFunction in case parameters are empty
if [ -z "$GITLAB_PASSWORD" ] || [ -z "$GITLAB_USERNAME" ]
then
   echo "User name and password must be given as parameters.";
   helpFunction
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


VERSION="print_rabbitmq"
GITLAB_PASSWORD=$( rawurlencode $GITLAB_PASSWORD )  # special char must be encoded


REPO=https://${GITLAB_USERNAME}:${GITLAB_PASSWORD}@gitlab.teclib-erp.com/teclib/odoo-box.git


CLONE_DIR="/home/pi/teclib"
echo "Remove dir : ${CLONE_DIR}"
rm -rf "${CLONE_DIR}"

if [ ! -d $CLONE_DIR ]; then
    if [ ${GIT_LOCAL} -eq 0 ]; then
        echo "Clone Gitlab repo..."
        mkdir -p "${CLONE_DIR}"
        git clone -b ${VERSION} --no-local --no-checkout --depth 1 "${REPO}" "${CLONE_DIR}"

        if [ $? -eq 0 ]; then
            echo "Git Clone Done."
        else
            echo "Git Clone Fail."
            exit
        fi
    else
        GIT_LOCAL_PATH="${LOCAL_TEMP}/local"
        echo "Using local git datas in ${GIT_LOCAL_PATH}"
        if [ ! -d "$GIT_LOCAL_PATH" ]; then
            mkdir -p "${GIT_LOCAL_PATH}"
            git clone -b ${VERSION} --depth 1 "${REPO}" "${GIT_LOCAL_PATH}"

            if [ $? -eq 0 ]; then
                echo "Git Clone Done."
            else
                echo "Git Clone Fail."
                exit
            fi
        fi
    fi
fi
