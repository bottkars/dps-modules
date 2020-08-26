#!/bin/bash
function ppdd_curl {
    local url
    url="https://${PPDD_FQDN}:3009/rest/${1#/}"
    shift || return # fail if we weren't passed at least x args
    local sleep_seconds=10
    local retry=0
    local retries=5
    local result=""
    while [[ -z $result ]]
        do
        if [[ $retry -gt $retries ]]
            then
            echo "exceeded max retries of $retries" >&2
            break
        fi
        [[ "${DEBUG}" == "TRUE" ]] && echo $url ${ppdd_curl_args[@]} >&2
        result=$(curl -ks "$url" \
        "${ppdd_curl_args[@]}" "$@"
        )
    [[ "${DEBUG}" == "TRUE" ]] && echo $result >&2
    [[ "${DEBUG}" == "TRUE" ]] && echo $retry >&2
       ((retry++))
       if [[ $(echo $result | jq -r 'select(.code != null)' 2> /dev/null) &&  $(echo $result | jq -r 'select(.code != 0)' 2> /dev/null) ]]
       #     ### eval section for return code will be added here
            then
                echo $result >&2
                local errorlevel=$(echo $result | jq -r '.code') 
                case $errorlevel in 
                    400|401)
                    echo "access denied" >&2
                    return 1
                    ;;
                    404)
                    echo "resource does not exist or is deleted" >&2
                    return 1
                    ;;
                    5040|5417|5028)
                    return 1
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



function get_ppdd_token {
    local password=$1
    local ppdd_adminuser=${2:-sysadmin}
    local ppdd_curl_args=(
    -XPOST 
    -H 'content-type: application/json' 
    -d '{"username":"'${ppdd_adminuser}'","password":"'${password}'"}'
    )
    echo "${ppdd_curl_args[@]}" >&2
    if [[ (local response=$(curl -ks --include "https://${PPDD_FQDN}:3009/rest/v1.0/auth" "${ppdd_curl_args[@]}" )) ]]
    then
        echo "${response[@]}" >&2
        local token=$(echo "${response[@]}" | grep "X-DD-AUTH-TOKEN:")
        echo $token
    else
        echo "error getting token" >&2
        return 1 
    fi     
}


function get_ppdd_system_id {
    local token="${1-$PPDD_TOKEN}"
    ppdd_curl_args=(
    -XGET    
    -H "content-type: application/json"
    -H "$token"
    )
    ppdd_curl "v1.0/system"   | jq -r .uuid
}

function get_ppdd_vdisks {
    local token=${1-$PPDD_TOKEN}
    local systemid=${2-$PPDD_SYSTEM_ID}
    systemid=${systemid//:/%3A} #
    ppdd_curl_args=(
    -XGET    
    -H 'content-type: application/json' 
    -H $token
    )
    ppdd_curl "v2.0/dd-systems/${systemid}/protocols/vdisk/devices"
}

function get_ppdd_ddboost {
    local token=${1-$PPDD_TOKEN}
    local systemid=${2-$PPDD_SYSTEM_ID}
    systemid=${systemid//:/%3A}
    ppdd_curl_args=(
    -XGET    
    -H 'content-type: application/json' 
    -H $token
    )
    ppdd_curl  "v2.0/dd-systems/${systemid}/protocols/ddboost"
}

function get_ppdd_users {
    local token=${1-$PPDD_TOKEN}
    local systemid=${2-$PPDD_SYSTEM_ID}
    systemid=${systemid//:/%3A}
    ppdd_curl_args=(
    -XGET    
    -H 'content-type: application/json' 
    -H "$token"
    )
    ppdd_curl "v1.0/dd-systems/${systemid}/users" | jq -r '.|= del(.paging_info)'
}




function set_ppdd_user_password {
    local user_id=${1}
    local current_password=${2}
    local new_password=${3}
    local token=${4-$PPDD_TOKEN}
    local systemid=${5-$PPDD_SYSTEM_ID}
    systemid=${systemid//:/%3A}
    ppdd_curl_args=(
    -XPUT    
    -H 'content-type: application/json' 
    -H "$token"
    -d '{
        "current_password": "'$current_password'",
        "new_password": "'$new_password'"
        }'  
    )
    ppdd_curl "/v1.0/dd-systems/${systemid}/users/${user_id}" 
}

function set_ppdd_ddboost {
    local token=${1-$PPDD_TOKEN}
    local systemid=${2-$PPDD_SYSTEM_ID}
    systemid=${systemid//:/%3A}
    ppdd_curl_args=(
    -XPUT    
    -H 'content-type: application/json' 
    -H $token
    -d '{ "operation": "enable"
    }'  
    )
    curl -ks "https://${PPDD_FQDN}:3009/rest/v1.0/dd-systems/${systemid}/protocols/ddboost" "${ppdd_curl_args[@]}"
}


function set_ppdd_cloudprovider {
    local primary_key=${1}
    local seconds=${2}
    local token=${3-$PPDD_TOKEN}
    local systemid=${4-$PPDD_SYSTEM_ID}
    systemid=${systemid//:/%3A}
    ppdd_curl_args=(
    -XPOST    
    -H 'content-type: application/json' 
    -H $token
    -d '{ "cloud_provider": "azure",
    "name": "localstems",
    "azure": {
        "account_name": "localstems",
        "primary_key": "'${primary_key}'",
        "secondary_key": "'${secondary_key}'"
        }
    }'  
    )
    curl -ks "https://${PPDD_FQDN}:3009/rest/v2.0/dd-systems/${systemid}/cloud-profiles" "${ppdd_curl_args[@]}"
}




function get_ppdd_licenses {
    local token=${1-$PPDD_TOKEN}
    local systemid=${2-$PPDD_SYSTEM_ID}
    systemid=${systemid//:/%3A}
    ppdd_curl_args=(
    -XGET   
    -H 'content-type: application/json' 
    -H $token
    )
    ppdd_curl "/v2.0/dd-systems/${systemid}/licenses" "${ppdd_curl_args[@]}"
}
