#!/usr/bin/env bash

ROOT_UID=0

if [[ $UID != ${ROOT_UID} ]]; then
    echo "You don't have sufficient privileges to run this script. Run with sudo."
    exit 1
fi

echo "Please enter a password for the 'sa' user. It is used only the first time the database is initialized."
echo "    If the db is already initialized the value will be ignored"
echo "    (e.g. the provided mount, already has been used by a running MSSQL container)."


export SA_PASSWORD
export DATA_DIR=/var/lib/mssql/data

read -s -p "Enter 'sa' password: " SA_PASSWORD
mkdir -p ${DATA_DIR}

echo

docker stack deploy \
    --compose-file $(dirname "$0")/deploy.yaml \
  mssql