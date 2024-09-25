#!/bin/bash

## ERROR Function 

wrong() {
    if [[ "$?" != 0 ]]; then
        printf "\n-- ERR -- $1\n"
        exit 1
    else
        printf "\n-- DONE -- $2\n"
    fi
}

## Taking User Inputs & Creating Necessary directories

printf "\n\n---- USER Inputs For Odoo volume Backup ----\n\n"

echo "Enter the Project Name : "
read P_NAME

printf "List of backups availabale for the project $P_NAME \n"
docker volume ls | grep "${P_NAME}"

mkdir $HOME/"${P_NAME}"-data-backup
cd $HOME/"${P_NAME}"-data-backup


## Taking backup of the web-data volume

#======================================================================#

docker run --rm \
-v "${P_NAME}"-web-data:/volume \
-v $(pwd):/backup/ ubuntu tar czf /backup/"${P_NAME}"-web-data.tar.gz \
-C /volume .

wrong "Could Not create web data volume" "Web Data volume created"

#======================================================================#


## Taking backup of the db-data volume

docker run --rm \
-v "${P_NAME}"-db-data:/volume \
-v $(pwd):/backup/ ubuntu tar czf /backup/"${P_NAME}"-db-data.tar.gz \
-C /volume .

wrong "Could Not create db data volume" "DB Data volume created"

#======================================================================#

## Listing the created backup files

echo "Find the List of backups : "
ls -l $HOME/"${P_NAME}"-data-backup

## Putting all together and wrapup in one file

cd $HOME 

tar czvf "${P_NAME}"-docker-volume-backup-$(date +\%d-\%m-\%y).tar.gz $HOME/"${P_NAME}"-data-backup

wrong "Could Not Zipped" "Files are zipped Find list bellow"

ls -l "${P_NAME}"-docker-volume-backup-$(date +\%d-\%m-\%y).tar.gz
