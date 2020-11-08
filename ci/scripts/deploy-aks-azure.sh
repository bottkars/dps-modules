#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
source dps-modules/ci/functions/ppdm_functions.sh


if [[ -d ppdm-config ]]
then
    PPDM_CONFIG_VERSION=$(cat ./ppdm-config/version) 
    echo "Found PPDM confiog file, evaluating Variables from vonfiguration Version ${PPDM_CONFIG_VERSION}"
    eval "$(jq -r 'keys[] as $key | "export \($key)=\"\(.[$key].value)\""' ./ppdm-config/tf-output-${PPDM_CONFIG_VERSION}.json)"
fi
echo "Connectring to Azure . . . "
if [[ "$DEVICELOGIN" == "TRUE" ]]
then
    az login --use-device-code --output tsv
else 
    az login --service-principal \
        -u ${AZURE_CLIENT_ID} \
        -p ${AZURE_CLIENT_SECRET} \
        --tenant ${AZURE_TENANT_ID} \
        --output tsv
fi        
az account set --subscription ${AZURE_SUBSCRIPTION_ID}  

az extension add --name aks-preview

az aks create -g ${RESOURCE_GROUP} \
 -n ${AKS_CLUSTER_NAME} \
 --network-plugin azure \
 -k 1.17.11 \
 --aks-custom-headers EnableAzureDiskFileCSIDriver=true \
 --subscription ${AZURE_SUBSCRIPTION_ID} \
 --generate-ssh-keys \
 --vnet-subnet-id "/subscriptions/${AZURE_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Network/virtualNetworks/${RESOURCE_GROUP}-virtual-network/subnets/${RESOURCE_GROUP}-aks-subnet"

az aks get-credentials --resource-group ${RESOURCE_GROUP} --name ${AKS_CLUSTER_NAME}

kubectl create -f "https://tanzuemea.tmc.cloud.vmware.com/installer?id=5ee191fe85a52e9dd2a9c135d406cd838879f00775960950a73596cb8631260e&source=attach"
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/azuredisk-csi-driver/master/deploy/example/snapshot/storageclass-azuredisk-snapshot.yaml


