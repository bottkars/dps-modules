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

MYSQLSTATE=$(az mysql server show  \
    --ids ${CDRS_MYSQL_ID} \
    --output tsv --query "userVisibleState"
)

case  $CDRS_MYSQL_STATE  in
                Ready)     
                echo "MySQL Instance already running, nothing to do here"
                ;;
                *)
                echo "MySQL Server not running, starting now"
                az mysql server restart \
                --ids ${CDRS_MYSQL_ID}
                ;;
esac

CDRS_SERVER_STATE=$(az vm show  \
    --ids ${CDRS_SERVER_ID} \
    --output tsv --query "provisioningState"
)
echo "Server state is ${CDRS_SERVER_STATE}"
case  $CDRS_SERVER_STATE  in
                Succeeded)     
                echo "CDRS Server already running, nothing to do here"
                ;;
                *)
                echo "CDRS Server not running, starting now"
                az vm  restart \
                    --ids ${CDRS_SERVER_ID} \
                    --no-wait
                until az vm show \
                    --ids ${CDRS_SERVER_ID} \
                    --output json --query "provisioningState=='Succeeded'" 
                do 
                    echo "waiting for server to start"
                    sleep 30
                done
                ;;
esac

