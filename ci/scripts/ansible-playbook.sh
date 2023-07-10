#!/bin/bash
set -eu
if [[ "${DEBUG}" == "TRUE" ]]
    then set -x
    export PLAYBOOK="${PLAYBOOK} -vvv"
fi    
figlet DPS Automation



echo "Evaluating if ppdm config file is passed"

if [[ -d ppdm-config ]]
then
    if [[ -f ppdm-config/version ]] 
    then
        PPDM_CONFIG_VERSION=$(cat ./ppdm-config/version) 
        echo "Found PPDM config file, evaluating Variables from configuration Version ${PPDM_CONFIG_VERSION}"
        eval "$(jq -r 'keys[] as $key | "export \($key)=\"\(.[$key].value)\""' ./ppdm-config/tf-output-${PPDM_CONFIG_VERSION}.json)"
    elif [[ -f ppdm-config/metadata ]] 
    then
        echo "found dps-terraform config metadata"   
        eval $(jq -r 'to_entries|map("export \(.key)=\"\(.value|tostring)\"")|.[]' ppdm-config/metadata)
    else 
    echo "no config found"    
    fi
fi
echo

if [[ -z $KUBE_CONFIG ]]
then
    echo "Setting Kube Config"
    mkdir -p $HOME/.kube
    echo $KUBE_CONFIG > $HOME/.kube/config
fi

if [[ -d vars ]]
then
    while IFS=": " read -r field1 field2
    do
         export $field1=$field2
    done < vars/vars.yml
fi

if [[ -d varsfile ]]
then
    VARS_URL=$(cat ./varsfile/url) 
    VARS_FILE=${VARS_URL##*/}
    echo "Found vars file ${VARS_FILE} at varsfile/"
    echo "Calling Playbook ${PLAYBOOK}"
    ansible-playbook ${PLAYBOOK} --extra-vars "@varsfile/${VARS_FILE}"
else
    ansible-playbook ${PLAYBOOK}
fi

