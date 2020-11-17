#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
source dps-modules/ci/functions/ppdm_functions.sh


KUBECONFIG_VERSION=$(cat ./kubeconfig/version) 
AKSCONFIG_VERSION=$(cat ./aksconfig/version) 

echo "Evaluating if ppdm config file is passed"

if [[ -d ppdm-config ]]
then
    PPDM_CONFIG_VERSION=$(cat ./ppdm-config/version) 
    echo "Found PPDM config file, evaluating Variables from configuration Version ${PPDM_CONFIG_VERSION}"
    eval "$(jq -r 'keys[] as $key | "export \($key)=\"\(.[$key].value)\""' ./ppdm-config/tf-output-${PPDM_CONFIG_VERSION}.json)"
fi
echo




export KUBECONFIG=${PWD}/kubeconfig/kubeconfig-${KUBECONFIG_VERSION}.json
export K8S_FQDN=$(jq -r .fqdn  ${PWD}/aksconfig/aksconfig-${AKSCONFIG_VERSION}.json)
kubectl apply -f  ${PPDM_ADMIN_TEMPLATE}
kubectl apply -f  ${PPDM_RBAC_TEMPLATE}

export PPDM_K8S_TOKEN=$(kubectl get secret "$(kubectl -n kube-system get secret | grep ppdm-admin | awk '{print $1}')" \
-n kube-system --template={{.data.token}} | base64 -d)


if [[ $RUN_PPDM_PLAYBOOK == "TRUE" ]]
then
{
    echo "Calling Playbook ${PLAYBOOK}"
    ansible-playbook ${PLAYBOOK}
}


export timestamp="$(date '+%Y%m%d.%-H%M.%S+%Z')"


PPDM_K8S_OUTPUT_FILE="$(echo "$PPDM_K8S_FILE" | envsubst )"
echo $PPDM_K8S_TOKEN > k8stoken/${PPDM_K8S_OUTPUT_FILE}