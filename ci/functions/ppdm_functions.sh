#!/bin/bah

function get_ppdm_token {
    local password=$1
    local token=$(curl -k -sS --request POST \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
    --url "https://${PPDM_FQDN}:8443/api/v2/login" -k \
    --header 'content-type: application/json' \
    --data '{"username":"admin","password":"'${password}'"}' | jq -r .access_token )
    echo $token
}


function get_ppdm_configuration {
    local token=${1}
    local configuration=$(curl -k -s --request GET \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
    --header "Authorization: Bearer ${token}" \
    --url "https://${PPDM_FQDN}:8443/api/v2/configurations" | jq -r ".content[0]" )
    echo $configuration
}


function get_ppdm_config_completionstate {
    local token=${1}
    local configuration_id=${2}
    local completionstate=$(curl -ks  \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
    --header "Authorization: Bearer ${token}" \
    --url "https://${PPDM_FQDN}:8443/api/v2/configurations/${configuration_id}/config-status" | jq -r ".percentageCompleted")
    echo ${completionstate}
}

function set_ppdm_configuration {
    local token=${1}
    local configuration_id=${2}
    local configuration=${3}
    request=$(curl -ks --request PUT \
    --url "https://${PPDM_FQDN}:8443/api/v2/configurations/${configuration_id}" \
    --header "content-type: application/json" \
    --header "Authorization: Bearer ${token}" \
    --data "$configuration")
    echo $request
}

function get_ppdm_config_state {
    local token=${1}
    local configuration_id=${2}
    local state=$(    
    curl -ks  \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
    --header "Authorization: Bearer ${token}" \
    --fail \
    --url "https://${PPDM_FQDN}:8443/api/v2/configurations/${configuration_id}/config-status" | jq -r ".status"
    )
    echo $state
}




function create_ppdm_credentials {
    local token=${1}
    local type=${2}
    local name=${3}
    local password=${4}
    local request=$(curl -ks --request POST \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
    --url "https://${PPDM_FQDN}:8443/api/v2/credentials" \
    --header "content-type: application/json" \
    --header "Authorization: Bearer ${token}" \
    --data "{\"type\":\"${type}\", \"name\": \"${name}\", \"username\": \"${name}\", \"password\": \"${password}\"}")
    echo $request
    }

function get_ppdm_credentials {
    local token=${1}
    local request=$(curl -ks --request GET \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
    --url "https://${PPDM_FQDN}:8443/api/v2/credentials" \
    --header "content-type: application/json" \
    --header "Authorization: Bearer ${token}" )
    echo $request
    }    

function create_ppdm_inventory_source {
    local token=${1}
    local type=${2}
    local name=${3}
    local address=${4}
    local credentials_id=${5}
    local port=${6}
    local data="{
        \"name\": \"${name}\",
        \"type\": \"${type}\",
        \"address\": \"${address}\",
        \"port\": $port,
        \"credentials\": {
            \"id\": \"${credentials_id}\" 
            }
    }"
    if [[ "$type" == "VCENTER" ]]
        then
        local data=$(echo $data | jq -r '.details.vCenter.vSphereUiIntegration |= true')
    fi 
    echo $data | jq -r    
    local request=$(curl -ks --request POST \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
    --url "https://${PPDM_FQDN}:8443/api/v2/inventory-sources" \
    --header "content-type: application/json" \
    --header "Authorization: Bearer ${token}" \
    --data "${data}" \
    )  
    echo $request 
}

function get_ppdm_inventory_sources {
    local token=${1}
    local request=$(curl -ks --request GET \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
    --url "https://${PPDM_FQDN}:8443/api/v2/inventory-sources" \
    --header "content-type: application/json" \
    --header "Authorization: Bearer ${token}" \
    )  
    echo $request 
}

function delete_ppdm_inventory_source {
    local token=${1}
    local inventory_id=${2}
    local request=$(curl -ks --request DELETE \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
    --url "https://${PPDM_FQDN}:8443/api/v2/inventory-sources/${inventory_id}" \
    --header "content-type: application/json" \
    --header "Authorization: Bearer ${token}" \
    )  
    echo $request 
}
function get_ppdm_host_certificate {
    local token=${1}
    local port=${3}
    local host=${2}
    local type=host    
    request=$(curl -ks --request GET \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
    --url "https://${PPDM_FQDN}:8443/api/v2/certificates?host=${host}&port=$port&type=Host" \
    --header "Authorization: Bearer ${token}" )
    echo $request
}

function trust_ppdm_host_certificate {
    local token=${1}
    local certificate=${2}
    local cert_id=${3}
    request=$(curl -ks --request PUT \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
    --url "https://${PPDM_FQDN}:8443/api/v2/certificates/$cert_id" \
    --header "content-type: application/json" \
    --header "Authorization: Bearer ${token}" \
    --data "${certificate}")
    echo $request
}

function get_ppdm_certificates {
    local token=${1}
    request=$(curl -ks --request GET \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
        --url "https://${PPDM_FQDN}:8443/api/v2/certificates" \
        --header "Authorization: Bearer ${token}" )
    echo $request
}

function delete_ppdm_credentials {
    local token=${1}
    local credentials_id=${2}
    local request=$(curl -ks --request DELETE \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
    --url "https://${PPDM_FQDN}:8443/api/v2/credentials/${credentials_id}" \
    --header "content-type: application/json" \
    --header "Authorization: Bearer ${token}" )
    echo $request
    }  
function delete_ppdm_certificate {
    local token=${1}
    local certificates_id=${2}
    local request=$(curl -ks --request DELETE \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 5 \
    --retry-delay 5 \
    --url "https://${PPDM_FQDN}:8443/api/v2/certificates/${certificates_id}" \
    --header "content-type: application/json" \
    --header "Authorization: Bearer ${token}" )
    echo $request
    }  
