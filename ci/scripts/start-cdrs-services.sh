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

echo "Getting MySQL Server Status"

CDRS_MYSQL_STATE=$(az mysql server show  \
    --ids ${CDRS_MYSQL_ID} \
    --output tsv --query "userVisibleState"
)
echo "MySQL Server state is ${CDRS_MYSQL_STATE}"
case  $CDRS_MYSQL_STATE  in
                Ready)     
                echo "MySQL Instance already running, nothing to do here"
                ;;
                Dropping)
                echo "Something bad just happend"
                exit 1
                ;;
                Stopped)
                echo "MySQL Server not running, starting now"
                az mysql server start \
                --ids ${CDRS_MYSQL_ID}
                ;;
                Inaccessible|Disabled)
                echo "MySQL Server not running, starting now"
                az mysql server restart \
                --ids ${CDRS_MYSQL_ID}
                ;;
esac
echo "aitong 2 Minutes before starting CDRS VM"
sleep 120
echo "Getting CDRS VM State"
CDRS_SERVER_STATE=$(az vm show  \
    --ids ${CDRS_SERVER_ID} \
    --show-details \
    --output tsv --query "powerState"
)
echo "VM state is ${CDRS_SERVER_STATE}"
case  $CDRS_SERVER_STATE  in
                'VM running')     
                echo "CDRS Server already running, nothing to do here"
                ;;
                'VM deallocated')
                echo "CDRS VM not running, starting now"
                az vm  start \
                    --ids ${CDRS_SERVER_ID} \
                    --no-wait
                until $(az vm show \
                    --ids ${CDRS_SERVER_ID} \
                    --show-details \
                    --output json --query "powerState=='VM running'" )
                do 
                    echo "waiting for VM to start"
                    sleep 30
                done
                ;;
                'VM deallocating')
                az vm  restart \
                    --ids ${CDRS_SERVER_ID} \
                    --no-wait
                until $(az vm show \
                    --ids ${CDRS_SERVER_ID} \
                    --show-details \
                    --output tsv --query "powerState=='VM running'" )
                do 
                    echo "waiting for VM to start"
                    sleep 30
                done
                ;;
esac

