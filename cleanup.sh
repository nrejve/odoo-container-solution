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


echo "Enter the Project Name : "
read P_NAME

P_DIR=$HOME/"${P_NAME}" 

docker container rm -f "${P_NAME}"-db

wrong "Could not remove DB Container" "DB Container cleanup done" 

docker container rm -f "${P_NAME}"-odoo

wrong "Could not remove Odoo Container" "Odoo Container cleanup done" 

docker volume rm -f "${P_NAME}"-db-data

wrong "Could not remove DB Volume" "DB Volume cleanup done" 

docker volume rm -f "${P_NAME}"-web-data

wrong "Could not remove Web Volume" "Web Volume cleanup done" 

docker network rm -f "${P_NAME}"

wrong "Could not remove network" "Network cleanup done" 

rm -fr "${P_DIR}"

wrong "Could not remove Project DIR" "Project DIR  cleanup done" 

wrong "Something went wrong" "All done" 



