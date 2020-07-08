#!/bin/bash
function ppdm_curl {
    local url
    local ppdm_curl_args=${2}
    url="https://${PPDM_FQDN}:8443/api/v2/${1#/}"
    shift || return # function should fail if we weren't passed at least one argument
    local sleep_seconds=10
    local retry=0
    local result=""
    while [[ -z $result || $retry -gt 5 ]]
        do
        result=$(curl -ks "$url" \
        "${ppdm_curl_args[@]}"  "$@"
        )
        echo $result >&2
        ((retry++))
        if [[ $(echo $result | jq -r 'select(.code != null)') ]]
            ### eval section for return code will be added here
            then
                local errorlevel=$(echo $result | jq -r '.code') 
                echo $errorlevel >&2
                case $errorlevel in 
                    401)
                    echo "access denied" >&2
                    break
                    ;;
                    423)
                    echo "user locked, waiting for 5 Minutes " >&2
                    sleep 300
                    ;;
                    *)
                esac    
                result=""
            echo "sleeping for $sleep_seconds seconds" >&2
            sleep $sleep_seconds    
        fi
    done    
    echo $result
}



function get_ppdm_token {
    local password=$1
    ppdm_curl_args=(
    -XPOST    
    -H 'content-type: application/json' 
    -d '{"username":"admin","password":"'${password}'"}')
    ppdm_curl login "$ppdm_curl_args" | jq -r '.access_token'

}




function get_ppdm_configuration {
    local token=${1}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    ppdm_curl configurations $ppdm_curl_args | jq -r ".content[0]" 
}


function get_ppdm_config_completionstate {
    local token=${1}
    local configuration_id=${2}
    local ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    ppdm_curl "configurations/${configuration_id}/config-status" $ppdm_curl_args | jq -r 
}

function set_ppdm_configuration {
    local token=${1}
    local configuration_id=${2}
    local configuration=${3}
    local ppdm_curl_args=(
    -XPUT
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    -D "$configuration")
    ppdm_curl "configurations/${configuration_id}" $ppdm_curl_args
}

function get_ppdm_config_state {
    local token=${1}
    local configuration_id=${2}
    local ppdm_curl_args=( 
    -XGET       
    -H "Authorization: Bearer ${token}"
    )
    ppdm_curl "configurations/${configuration_id}/config-status" $ppdm_curl_args | jq -r
}


function create_ppdm_credentials {
    local token=${1}
    local type=${2}
    local name=${3}
    local password=${4}
    local ppdm_curl_args=(
    -XPOST    
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    -D '{
        "type":'"${type}"',
        "name": '"${name}"',
        "username": '"${name}"',
        "password": '"${password}"'
         }'
    )     
    ppdm_curl "credentials" $ppdm_curl_args | jq -r
    }

function get_ppdm_credentials {
    local token=${1}
    local ppdm_curl_args=(
    -XGET
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    )
    ppdm_curl credentials $ppdm_curl_args | jq -r
    }    

function create_ppdm_inventory_source {
    local token=${1}
    local type=${2}
    local name=${3}
    local address=${4}
    local credentials_id=${5}
    local port=${6}
    local data='{
        "name": '"${name}"',
        "type": '"${type}"',
        "address": '"${address}"',
        "port": $port,
        "credentials": {
            "id": '"${credentials_id}"' 
            }
    }'
    if [[ "$type" == "VCENTER" ]]
        then
        local data=$(echo $data | jq -r '.details.vCenter.vSphereUiIntegration |= true')
    fi 
    local ppdm_curl_args=(
    -XPOST
    -H 'content-type: application/json'
    -H "Authorization: Bearer ${token}"
    -D "${data}"
    )  
    ppdm_curl inventory-sources $ppdm_curl_args | jq -r
}

function get_ppdm_inventory_sources {
    local token=${1}
    local ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    ppdm_curl inventory-sources $ppdm_curl_args | jq -r
}

function delete_ppdm_inventory_source {
    local token=${1}
    local inventory_id=${2}
    local ppdm_curl_args=(
    -XDELETE
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    )  
    ppdm_curl "inventory-sources/${inventory_id}" $ppdm_curl_args | jq -r
}

function get_ppdm_host_certificate {
    local token=${1}
    local port=${3}
    local host=${2}
    local type=host    
    local ppdm_curl_args=(
    -XGET 
    -H "Authorization: Bearer ${token}" 
    )
    ppdm_curl "certificates?host=${host}&port=$port&type=Host" $ppdm_curl_args | jq .
}

function trust_ppdm_host_certificate {
    local token=${1}
    local certificate=${2}
    local cert_id=${3}
    local ppdm_curl_args=(
    -XPUT
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    -D"${certificate}"
    )
    ppdm_curl "certificates/$cert_id" $ppdm_curl_args | jq -r
    }

function get_ppdm_certificates {
    local token=${1}
    local ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" 
    )
    ppdm_curl certificates $ppdm_curl_args  | jq -r
}

function delete_ppdm_credentials {
    local token=${1}
    local credentials_id=${2}
    local ppdm_curl_args=(
    -XDELETE
    -H "content-type: application/json" 
    -H "Authorization: Bearer ${token}"
    )
    ppdm_curl "credentials/${credentials_id}" $ppdm_curl_args
    }  
function delete_ppdm_certificate {
    local token=${1}
    local certificates_id=${2}
    local ppdm_curl_args=(
    -XDELETE
    -H "content-type: application/json" 
    -H "Authorization: Bearer ${token}"
    )
    ppdm_curl "certificates/${certificates_id}"  $ppdm_curl_args
    }  