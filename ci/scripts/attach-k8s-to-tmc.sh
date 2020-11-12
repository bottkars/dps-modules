#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
KUBECONFIG_VERSION=$(cat ./kubeconfig/version) 
AKSCONFIG_VERSION=$(cat ./aksconfig/version) 

echo "getting KUBECONFIG"

export KUBECONFIG=${PWD}/kubeconfig/kubeconfig-${KUBECONFIG_VERSION}.json
K8S_FQDN=$(jq -r .fqdn  ${PWD}/aksconfig/aksconfig-${AKSCONFIG_VERSION}.json)
export TMC_CLUSTERNAME=$( echo ${K8S_FQDN%%.*}  | tr '[:upper:]' '[:lower:]')
tmc version
echo "Attaching ${TMC_CLUSTERNAME} to ${TMC_CLUSTERGROUP}"
tmc login --name ${TMC_CONTEXT} --no-configure
tmc cluster attach \
    --cluster-group ${TMC_CLUSTERGROUP} \
    --name ${TMC_CLUSTERNAME}


kubectl apply -f k8s-attach-manifest.yaml
timestamp="$(date '+%Y%m%d.%-H%M.%S+%Z')"
TMC_K8S_MANIFEST_FILE="$(echo "TMC_K8S_MANIFEST" | envsubst '$timestamp')"
copy k8s-attach-manifest.yaml tmcmanifest/${TMC_K8S_MANIFEST_FILE}