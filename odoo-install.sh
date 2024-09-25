#!/bin/bash


## Functions 

wrong() {

    if [[ "$?" != 0 ]]; then
        printf "\n-- ERR -- $1\n"
        exit 1
    else
        printf "\n-- DONE -- $2\n"
    fi
}

dbContainer() {

    docker run -d \
    -e POSTGRES_USER=odoo \
    -e POSTGRES_PASSWORD=odoo \
    -e POSTGRES_DB=postgres \
    -e PGDATA=/var/lib/postgresql/data/pgdata \
    -v "${P_NAME}"-db-data:/var/lib/postgresql/data/pgdata \
    --network "${P_NAME}" \
    --name "${P_NAME}"-db --network-alias db postgres:"${DB_VERSION}"
}

backupCon() {

    docker run --rm -v "${P_NAME}"-"$1"-data:/volume -v $(pwd):/backup \
    ubuntu tar xzf /backup/"${P_NAME}"-"$1"-data.tar.gz -C /volume .
}

odooContainer() {

    docker run -d \
    -v "${P_DIR}"/extra-addons:/mnt/extra-addons \
    -v "${P_DIR}"/config:/etc/odoo \
    -p "$ODOO_PORT":8069 \
    -v "${P_NAME}"-web-data:/var/lib/odoo \
    -e DB_HOST=db \
    --network "${P_NAME}" \
    --name "${P_NAME}"-odoo \
    odoo:"${ODOO_VERSION}"
}

confClone() {
   git clone https://gitlab.com/nazmul23/erp-odoo-conf.git \
   --depth 1 --branch "${OB}" "${P_DIR}"/config 
}

## User inputs

while true; do

    printf "\n\n---- USER Inputs For Odoo Containered Installations ----\n\n"
    echo "=================================================================="
    echo "Enter the Project Name : "
    read P_NAME
    echo "=================================================================="
    echo "Enter the Odoo Version you want to install (I.e 17): "
    read ODOO_VERSION
    echo "=================================================================="
    echo "Do you want Enterprise Addons included? "
    read -p "Enter 'yes' to include, or 'no' to NOT include: " EA
    echo "=================================================================="
    echo "Enter the PORT number you want Odoo to be exposed (I.e 8015): "
    read ODOO_PORT
    echo "=================================================================="
    echo "Enter the Postgres DB Version you want to install (I.e 16): "
    read DB_VERSION
    echo "=================================================================="
    echo "Set the Odoo Admin Password: "
    read -s ODOO_ADMIN_PASS
    echo "=================================================================="
    echo "Do you want to recover from backup?"
    read -p "Enter 'yes' to proceed, or 'no' to go without backup: " bconfirm
    echo "=================================================================="
    if [ "$bconfirm" = "yes" ]; then
        echo "Enter the Absolute path of the backup (i.e /path/to/backup) "
        read BACKUP_LOC
        echo "=================================================================="

        ls -l "${BACKUP_LOC}"/"${P_NAME}"-db-data.tar.gz

        wrong "Could not find the DB Data backup" "DB Data backup found"

        ls -l "${BACKUP_LOC}"/"${P_NAME}"-web-data.tar.gz

        wrong "Could not find the Web data backup" "Web Data backup found"
        
    elif [ "$bconfirm" != "no" ]; then
        echo "Going without backup"
    else
        echo "Invalid input. Please enter 'yes' or 'no'."
    fi

    input_summary="
    You have inputted following information
    Project Name: $P_NAME
    Odoo Version : $ODOO_VERSION
    Odoo Port : $ODOO_PORT
    DB Version : $DB_VERSION
    Enterprise Addons : $EA
    Installing from backup : $bconfirm
    "
    echo "=================================================================="
    printf "$input_summary"
    echo "=============================================================="


    ## Confirm input information
    echo "Are you sure this information is correct?"
    read -p "Enter 'yes' to proceed, or 'no' to input again: " confirm
    echo "=================================================================="

    if [ "$confirm" = "yes" ]; then
        echo "Information confirmed. Proceeding to the next step..."
        break
    elif [ "$confirm" != "no" ]; then
        echo "Invalid input. Please enter 'yes' or 'no'."
    else
        echo "Information not confirmed. Please input again."
    fi
done


## variables
P_DIR=$HOME/"${P_NAME}"

disFunc() {
    O_CON=$(docker inspect --format="{{.Name}}" "${P_NAME}"-odoo | awk -F/ '{print $2}')
    D_CON=$(docker inspect --format="{{.Name}}" "${P_NAME}"-db | awk -F/ '{print $2}')
    D_VOL=$(docker volume ls | grep "${P_NAME}"-db-data | awk '{ print $2 }')
    A_VOL=$(docker volume ls | grep "${P_NAME}"-web-data | awk '{ print $2 }')
}


## Necessary Directories
mkdir "${P_DIR}"/config -p && mkdir "${P_DIR}"/extra-addons/enterprise-addons -p

wrong "Could not create directories" "Directory Created"


## Wheather to add enterprise addons or not
if [ "$EA" = "yes" ]; then

    git clone https://gitlab.com/nazmul23/enterprise-addons \
    --depth 1 --branch "${ODOO_VERSION}" "${P_DIR}"/extra-addons/enterprise-addons

    echo "Enterprise Addons Created"

else 
    echo "Enterprise Addons Skipped"
fi

wrong "Could not Added Enterprise Addons" "Enterprise Addons Created/Skipped"

## Conf requirement conditions
if [[ "$ODOO_VERSION" == 17 && "$EA" == "yes" ]]; then

    OB=17-y
    confClone

elif [[ "$ODOO_VERSION" == 17 && "$EA" == "no" ]]; then

    OB=17-n
    confClone

elif [[ "$ODOO_VERSION" != 17 && "$EA" == "yes" ]]; then

    OB=n-17-y
    confClone

elif [[ "$ODOO_VERSION" != 17 && "$EA" == "no" ]]; then

    OB=n-17-n
    confClone
fi

## Modify conf file with the current env variables
sed -i "s/\${ODOO_VERSION}/${ODOO_VERSION}/g" "${P_DIR}"/config/odoo.conf
sed -i "s/\${ODOO_ADMIN_PASS}/${ODOO_ADMIN_PASS}/g" "${P_DIR}"/config/odoo.conf


wrong "Can not proceed to the container stage" "Creating Container elements"

## Docker network creations for isolations
docker network create "${P_NAME}"

wrong "Can not create docker network" "Isolated Network Created"

## Backup Confirmation
if [ "$bconfirm" = "yes" ]; then

    cd "${BACKUP_LOC}"

    ## Running from backup
    backupCon db
    backupCon web

    ## DB Container create
    dbContainer

    wrong "Can not create DB Container from backup" "DB Container Deployed from backup"

    ## Odoo Container create
    odooContainer

    wrong "Can not create Odoo Container from backup" "Odoo Container Deployed from backup"
    
elif [ "$bconfirm" = "no" ]; then

    ## DB Container create
    dbContainer

    wrong "Can not create DB Container" "DB Container Deployed"

    ## Odoo Container create
    odooContainer

    wrong "Can not create Odoo Container" "Odoo Container Deployed"

fi

wrong "Deployment Not Done, Something went wrong" "Deployment Done !"

disFunc

    summary="
    Project Directory: ${P_DIR}
    Odoo Container Name: ${O_CON}
    Odoo Container Port: ${ODOO_PORT}
    Database Container Name: ${D_CON}
    Application Persistent VOL Name: ${A_VOL}
    Database Persistent VOL Name: ${D_VOL}
"

echo "=================================================================="
printf "\n\n---- Summary ----------------\n"
printf "$summary"
echo "=================================================================="





