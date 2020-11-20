#!/bin/bash
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
figlet DPS Automation
source dps-modules/ci/functions/ppdm_functions.sh


KUBECONFIG_VERSION=$(cat ./kubeconfig/version) 




export KUBECONFIG=${PWD}/kubeconfig/kubeconfig-${KUBECONFIG_VERSION}.json
echo "Creating Wordpress App in ${NAMESPACE}"
cd ./${TEMPLATE_PATH}
cat <<EOF >./kustomization.yaml
secretGenerator:
- name: mysql-pass
  literals:
  - password=${WP_PASSWORD}
resources:
  - namespace.yaml  
  - mysql-deployment.yaml
  - wordpress-deployment.yaml

EOF

cat <<EOF >./namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
  labels: 
    ppdm_policy: ${PPDM_POLICY}

EOF

kubectl apply -k ./ --namespace ${NAMESPACE}
