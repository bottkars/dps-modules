#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
source dps-modules/ci/functions/ppdm_functions.sh


KUBECONFIG_VERSION=$(cat ./kubeconfig/version) 




export KUBECONFIG=${PWD}/kubeconfig/kubeconfig-${KUBECONFIG_VERSION}.json
echo "Creating MYSQL App in ${MYSQL_NAMESPACE}"
kubectl create namespace ${MYSQL_NAMESPACE}
kubectl apply -f ${MYSQL_SECRET} --namespace ${MYSQL_NAMESPACE}
kubectl apply -f ${MYSQL_PVC} --namespace ${MYSQL_NAMESPACE}
kubectl apply -f ${MYSQL_DEPLOYMENT} --namespace ${MYSQL_NAMESPACE}
