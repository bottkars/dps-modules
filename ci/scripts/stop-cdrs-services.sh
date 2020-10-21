#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
source dps-modules/ci/functions/ppdm_functions.sh
source dps-modules/ci/functions/yaml.sh


az login --service-principal \
    -u ${AZURE_CLIENT_ID} \
    -p ${AZURE_CLIENT_SECRET} \
    --tenant ${AZURE_TENANT_ID} \
    --output tsv
az account set --subscription ${AZURE_SUBSCRIPTION_ID}  


echo "Getting CDRS VM State"
CDRS_SERVER_STATE=$(az vm show  \
    --ids ${CDRS_SERVER_ID} \
    --show-details \
    --output tsv --query "powerState"
)
echo "VM state is ${CDRS_SERVER_STATE}"
case  $CDRS_SERVER_STATE  in
                'VM running')     
                echo "CDRS VM running, stopping now"
                az vm deallocate \
                    --ids ${CDRS_SERVER_ID} \
                    --no-wait
                until $(az vm show \
                    --ids ${CDRS_SERVER_ID} \
                    --show-details \
                    --output json --query "powerState=='VM deallocated'" )
                do 
                    echo "waiting for VM to deallocate"
                    sleep 30
                done    
                ;;
                'VM deallocating')
                echo 'VM already Deallocating, wating to be done'
                until $(az vm show \
                    --ids ${CDRS_SERVER_ID} \
                    --show-details \
                    --output json --query "powerState=='VM deallocated'" )
                do 
                    echo "waiting for VM to be deallocated"
                    sleep 30
                done
                ;;
                'VM deallocated')
                echo "CDRS VM not running, nothing to do here"
                ;;
esac

echo "Done Deallocating"


echo "Stopping CDRS VM and Database"
echo "Getting MySQL Server Status"

CDRS_MYSQL_STATE=$(az mysql server show  \
    --ids ${CDRS_MYSQL_ID} \
    --output tsv --query "userVisibleState"
)
echo "MySQL Server state is ${CDRS_MYSQL_STATE}"

case  $CDRS_MYSQL_STATE  in
                Ready|Inaccesible)     
                echo "MySQL Instance running, Stopping now"
                az mysql server stop \
                --ids ${CDRS_MYSQL_ID} --verbose
                ;;
                Disabled)
                echo "MySQL Server not running, nothing to do Here"
                ;;
                Dropping)
                echo "Something bad just happend"
                exit 1
                ;;
esac


