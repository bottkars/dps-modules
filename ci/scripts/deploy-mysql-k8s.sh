#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
source dps-modules/ci/functions/ppdm_functions.sh


KUBECONFIG_VERSION=$(cat ./kubeconfig/version) 




export KUBECONFIG=${PWD}/kubeconfig/kubeconfig-${KUBECONFIG_VERSION}.json

kubectl create namespace ${MYSQL_NAMESPACE}
kubectl apply -f ${MYSQL_SECRET} --namespace ${MYSQL_NAMESPACE}
kubectl apply -f ${MYSQL_PVC} --namespace ${MYSQL_NAMESPACE}
kubectl apply -f ${MYSQL_DEPLOYMENT} --namespace ${MYSQL_NAMESPACE}

export PPDM_K8S_TOKEN=$(kubectl get secret "$(kubectl -n kube-system get secret | grep ppdm-admin | awk '{print $1}')" \
-n kube-system --template={{.data.token}} | base64 -d)



echo "Calling Playbook ${PLAYBOOK}"

ansible-playbook ${PLAYBOOK}

timestamp="$(date '+%Y%m%d.%-H%M.%S+%Z')"

PPDM_K8S_FILE=ppdmk8stoken-$timestamp.json

PPDM_K8S_OUTPUT_FILE="$(echo "$PPDM_K8S_FILE" | envsubst '$timestamp')"
echo $PPDM_K8S_TOKEN > k8stoken/${PPDM_K8S_OUTPUT_FILE}