#!/bin/bash
function ppdm_curl {
    local url
    url="https://${PPDM_FQDN}:8443/api/v2/${1#/}"
    shift || return # function should fail if we weren't passed at least one argument
    local sleep_seconds=10
    local retry=0
    local result=""
    while [[ -z $result || $retry -gt 5 ]]
        do
        [[ "${DEBUG}" == "TRUE" ]] && echo $url ${ppdm_curl_args[@]} >&2
        result=$(curl -ks "$url" \
        "${ppdm_curl_args[@]}" "$@"
        )
        [[ "${DEBUG}" == "TRUE" ]] && echo $result >&2
        [[ "${DEBUG}" == "TRUE" ]] && echo $retry >&2
        ((retry++))
        if [[ $(echo $result | jq -r 'select(.code != null)' 2> /dev/null) ]]
            ### eval section for return code will be added here
            then
                local errorlevel=$(echo $result | jq -r '.code') 
                case $errorlevel in 
                    400|401)
                    echo "access denied" >&2
                    break
                    ;;
                    404)
                    echo "resource does not exist or is deleted" >&2
                    break
                    ;;
                    423)
                    echo "user locked, waiting for 5 Minutes " >&2
                    sleep 300
                    ;;
                    *)
                    echo "current State $errorlevel" >&2
                    ;;
                esac    
                result=""
            [[ "${DEBUG}" == "TRUE" ]] && echo "sleeping for $sleep_seconds seconds" >&2
            sleep $sleep_seconds    
        fi
    done    
    echo $result
}



function get_ppdm_token {
    local password=$1
    local ppdm_adminuser=${PPDM_ADMINUSER:-admin}
    ppdm_curl_args=(
    -XPOST    
    -H 'content-type: application/json' 
    -d '{"username":"'${ppdm_adminuser}'","password":"'${password}'"}')
    ppdm_curl login  | jq -r '.access_token'

}



function get_ppdm_configuration {
    local token=${1:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    ppdm_curl configurations | jq -r ".content[]" 
}


function get_ppdm_assets {
    local token=${1:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    ppdm_curl assets | jq '.content[]'
}

function get_ppdm_hosts {
    local token=${1:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    ppdm_curl hosts | jq '.content[]'
}

function get_ppdm_agent-registration-status {
    local token=${1:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    ppdm_curl agent-registration-status | jq -r #".content[0]" 
}

function get_ppdm_config_completionstate {
    local token=${2:-$PPDM_TOKEN}
    local configuration_id=${1}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    ppdm_curl "configurations/${configuration_id}/config-status" | jq -r '.percentageCompleted'
}

function set_ppdm_configurations {
    local token=${3:-$PPDM_TOKEN}
    local configuration_id=${1}
    local configuration=${2}
    ppdm_curl_args=(
    -XPUT
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    -d "${configuration}"
    )
    ppdm_curl "configurations/${configuration_id}" 
}

function get_ppdm_config-status {
    local token=${2:-$PPDM_TOKEN}
    local configuration_id=${1}
    ppdm_curl_args=( 
    -XGET       
    -H "Authorization: Bearer ${token}"
    )
    ppdm_curl "configurations/${configuration_id}/config-status"  | jq -r '.status'
}


function create_ppdm_credentials {
    local token=${4:-$PPDM_TOKEN}
    local type=${1}
    local name=${2}
    local password=${3}
    ppdm_curl_args=(
    -XPOST    
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    -d '{
        "type":"'${type}'",
        "name": "'${name}'",
        "username": "'${name}'",
        "password": "'${password}'"
         }'
    )     
    ppdm_curl "credentials"  | jq -r .
    }

function get_ppdm_credentials {
    local token=${1:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    )
    ppdm_curl credentials  | jq '.content[]'
    }    

function create_ppdm_inventory-source {
    local token=${6:-$PPDM_TOKEN}
    local type=${1}
    local name=${2}
    local address=${3}
    local credentials_id=${4}
    local port=${5}
    local data='{
        "name": "'${name}'",
        "type": "'${type}'",
        "address": "'${address}'",
        "port": '$port',
        "credentials": {
            "id": "'${credentials_id}'" 
            }
    }'
    if [[ "$type" == "VCENTER" ]]
        then
        local data=$(echo $data | jq -r '.details.vCenter.vSphereUiIntegration |= true')
    fi 
    ppdm_curl_args=(
    -XPOST
    -H 'content-type: application/json'
    -H "Authorization: Bearer ${token}"
    -d "${data}"
    )  
    ppdm_curl inventory-sources  | jq -r
}

function get_ppdm_inventory-sources {
    local token=${1:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    ppdm_curl inventory-sources  | jq -r '.content[]'
}

function get_ppdm_locations {
    local token=${1:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    ppdm_curl locations  | jq -r 
}

function get_ppdm_common-settings {
    local token=${1:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    ppdm_curl common-settings  | jq -r
}


function get_ppdm_sdr-settings {
    local token=${10:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    ppdm_curl common-settings/SDR_CONFIGURATION_SETTING  | jq -r
}

function set_ppdm_sdr-settings {
    local token=${10:-$PPDM_TOKEN}
    local repositoryHost=${1}
    local repositoryPath=${2}
    local repositoryType=${3}
    local backupsEnabled=${4}
    local data=$(get_ppdm_sdr-settings)
    data=$(echo $data | jq 'del(._links)')
    data=$(echo $data | jq --arg repositoryHost ${repositoryHost} '(.properties[] | select(.name == "repositoryHost").value) |= $repositoryHost')
    data=$(echo $data | jq --arg repositoryPath ${repositoryPath} '(.properties[] | select(.name == "repositoryPath").value) |= $repositoryPath')
    data=$(echo $data | jq --arg repositoryType ${repositoryType} '(.properties[] | select(.name == "type").value) |= $repositoryType')
    data=$(echo $data | jq --arg backupsEnabled ${backupsEnabled} '(.properties[] | select(.name == "backupsEnabled").value) |= $backupsEnabled')
    ppdm_curl_args=(
    -XPUT
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    -d $data
    )  
    ppdm_curl common-settings/SDR_CONFIGURATION_SETTING  | jq -r
}

function get_ppdm_components {
    local token=${1:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    ppdm_curl components  | jq -r
}

function get_ppdm_components {
    local token=${1:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    ppdm_curl components  | jq -r
}


function get_ppdm_server-disaster-recovery-hosts {
    local token=${1:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    ppdm_curl server-disaster-recovery-hosts  | jq -r
}

function get_ppdm_storage-systems {
    local token=${1:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    ppdm_curl storage-systems  | jq '.content[]'
}

function delete_ppdm_inventory-source {
    local token=${2:-$PPDM_TOKEN}
    local inventory_id=${1}
    ppdm_curl_args=(
    -XDELETE
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    )  
    ppdm_curl "inventory-sources/${inventory_id}"  | jq -r
}



function get_ppdm_host_certificate {
    local token=${3:-$PPDM_TOKEN}
    local port=${2}
    local host=${1}
    local type=host    
    ppdm_curl_args=(
    -XGET 
    -H "Authorization: Bearer ${token}" 
    )
    ppdm_curl "certificates?host=${host}&port=$port&type=Host"  | jq .
}

function trust_ppdm_host_certificate {
    local token=${3:-$PPDM_TOKEN}
    local certificate=${1}
    local cert_id=${2}
    ppdm_curl_args=(
    -XPUT
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    -d "${certificate}"
    )
    ppdm_curl "certificates/$cert_id"  | jq -r
    }

function get_ppdm_certificates {
    local token=${1:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" 
    )
    ppdm_curl certificates   | jq -r
}

function delete_ppdm_credentials {
    local token=${2:-$PPDM_TOKEN}
    local credentials_id=${1}
    ppdm_curl_args=(
    -XDELETE
    -H "content-type: application/json" 
    -H "Authorization: Bearer ${token}"
    )
    ppdm_curl "credentials/${credentials_id}" 
    } 

function delete_ppdm_certificate {
    local token=${2:-$PPDM_TOKEN}
    local certificates_id=${1}
    ppdm_curl_args=(
    -XDELETE
    -H "content-type: application/json" 
    -H "Authorization: Bearer ${token}"
    )
    ppdm_curl "certificates/${certificates_id}"  
    }  