#!/bin/bash
########################################################################################################################
# PARAMETERS
########################################################################################################################
if [ $# -eq 0 ]
  then
    echo "No arguments supplied please add name for box"
    exit 1
fi

NAME=$1
PASSOWRD=teclib@
PERSONNAL_TOKEN=KBzKEk1fvd_nznwuLr3J
PROJECT_ID=746


########################################################################################################################
# CREATE SSH KEY
########################################################################################################################
if ! [ -d "ssh" ]; then
  mkdir ssh
fi

if ! [ -d "ssh/$NAME" ]; then
  mkdir "ssh/$NAME"
fi

if ! [ -f "ssh/$NAME/id_rsa" ]; then
  ssh-keygen -q -t rsa -N '' -C $NAME@teclib-box -f ssh/$NAME/id_rsa
  GITLAB_DATA='{"title": "'$NAME@teclib-box'", "key": "'$(cat ssh/$NAME/id_rsa.pub)'", "can_push": "false"}'
  curl --request POST --header "PRIVATE-TOKEN: $PERSONNAL_TOKEN" --header "Content-Type: application/json" --data "$GITLAB_DATA" "https://gitlab.teclib-erp.com/api/v4/projects/$PROJECT_ID/deploy_keys/"
fi
########################################################################################################################
# GIT DEPLOY TOKEN
########################################################################################################################
if ! [ -f "ssh/$NAME/gitlab-token" ]; then
  GITLAB_DATA='{"name": "'$NAME@teclib-box'", "expires_at": "2042-01-01", "username": "'$NAME'", "scopes": ["read_repository","read_registry","read_package_registry"]}'
  curl --request POST --header "PRIVATE-TOKEN: $PERSONNAL_TOKEN" --header "Content-Type: application/json" --data "$GITLAB_DATA" "https://gitlab.teclib-erp.com/api/v4/projects/$PROJECT_ID/deploy_tokens/" | jq '.token' > ssh/$NAME/gitlab-token
fi
# TODO : fix authentification error with generated token and remove this line
echo $PERSONNAL_TOKEN > ssh/$NAME/gitlab-david-token

if ! [ -f "ssh/$NAME/gitlab-user" ]; then
  echo $NAME@teclib-box > ssh/$NAME/gitlab-user
fi


########################################################################################################################
# EXECUTE PACKER
########################################################################################################################
packer build --var=name=$NAME -timestamp-ui  teclib-box.json