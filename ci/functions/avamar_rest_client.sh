#!/bin/bash
# Function Set for ddve on vsphere

function avamar_curl {
    local url
    local avamar_fqdn=${AVAMAR_FQDN:-$AVI_FQDN}
    url="https://${avamar_fqdn}/${1#/}"
    shift || return # fail if we weren't passed at least x args
    local sleep_seconds=10
    local retry=0
    local retries=5
    local result=""
    local return_code=1
    while [[ -z $result && "$return_code" != 0 ]]
        do
        if [[ $retry -gt $retries ]]
            then
            echo "exceeded max retries of $retries" >&2
            break
        fi
        [[ "${DEBUG}" == "TRUE" ]] && echo $url ${avi_curl_args[@]} >&2
        result=$(curl -ks "$url" \
        "${avi_curl_args[@]}" "$@"
        )
        return_code=$?
        [[ "${DEBUG}" == "TRUE" ]] && echo $return_code >&2
        [[ "${DEBUG}" == "TRUE" ]] && echo $result >&2
        [[ "${DEBUG}" == "TRUE" ]] && echo $retry >&2
        ((retry++))

        if [[ $(echo $result | jq -e 'select(.code != null)' 2> /dev/null) ]]
            ### eval section for return code will be added here
            then
                local errorlevel=$(echo $result | jq -e '.code' 2> /dev/null) 
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
    echo ${result//\\//} | jq -e . 2>/dev/null
}




function get_avamar_token {
    local av_password=${1:-$AVE_PASSWORD}
    local av_user=${2:-$AVE_USERNAME}    
    local apiver=${3:-v1}

    avi_curl_args=(
    -XPOST
    -H 'content-type: application/x-www-form-urlencoded' 
    --data-urlencode "grant_type=password"
    --data-urlencode "scope=write"
    --data-urlencode "username=$av_user"
    --data-urlencode "password=$av_password"
)
    local response=$(avamar_curl api/${apiver}/oauth/swagger)
    echo $response | jq -r '.access_token'
}

#    -F "username=root"
#    -F 'vcenter=null'
#    -F 'scope=all'
#    -F 'domain=%F2'
#    -F 'type=avamar'
#    -F "password=Change_Me12345_"
#grant_type=password&scope=all&username=root&domain=%2F&type=avamar&vcenter=null&password=Change_Me12345_




function create_avamar_oauth_client {
    avi_curl_args=(
    -XPOST
    -H 'Authorization: Basic cm9vdDpDaGFuZ2VfTWUxMjM0NV8K'
    -H 'content-type: application/json' 
    -d '{
            "accessTokenValiditySeconds": 1800,
            "authorizedGrantTypes": [
            "password"
            ],
            "autoApproveScopes": [
            "all"
            ],
            "clientName": "root",
            "clientSecret": "Change_Me12345_",
            "redirectUris": [
            "https://my-app-server/callback"
            ],
            "refreshTokenValiditySeconds": 43200,
            "scopes": [
            "read", "write"
            ]
            }'

    )
    local response=$(avamar_curl api/v1/oauth2/clients  | jq -r '.')
    echo $response
}





function get_avamar_clients {
    local domain=${1:-"./"}
    local apiver=${2:-"v1"}
    local avamar_token=${3:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $avamar_token"
    --data-urlencode domain=$domain
    --data-urlencode recursive=false
    )
    local response=$(avamar_curl api/${apiver}/clients)
    echo $response
}
function get_avamar_client {
    local cid=${1}
    local apiver=${2:-"v1"}
    local domain=${3:-"./"}
    local avamar_token=${4:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $avamar_token"
    --data-urlencode domain=$domain
    --data-urlencode recursive=false
    )
    local response=$(avamar_curl api/${apiver}/clients/${cid})
    echo $response
}

function get_avamar_proxies {
    local apiver=${1:-"v1"}
    local avamar_token=${2:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $avamar_token"
    )
    local response=$(avamar_curl api/${apiver}/proxies)
    echo $response | jq .content
}


function get_avamar_proxy {
    local cid=${1}
    local apiver=${2:-"v1"}
    local avamar_token=${3:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $avamar_token"
    --data-urlencode domain=$domain
    --data-urlencode recursive=false
    )
    local response=$(avamar_curl api/${apiver}/proxies/${cid})
    echo $response | jq .
}
function get_avamar_tasks {
    local cid=${1}
    local apiver=${2:-"v1"}
    local avamar_token=${3:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $avamar_token"
    --data-urlencode domain=$domain
    --data-urlencode recursive=false
    )
    local response=$(avamar_curl api/${apiver}/tasks/${cid})
    echo $response | jq .
}


# 
# /v1/system/status
# /v1/virtualcenters Get Virtual Centers
function get_avamar_status {
    local apiver=${1:-"v1"}
    local avamar_token=${2:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $avamar_token"
    --data-urlencode domain=$domain
    --data-urlencode recursive=false
    )
    local response=$(avamar_curl api/${apiver}/system/status)
    echo $response | jq .
}

function get_avamar_about-information
 {
    local apiver=${1:-"v1"}
    local avamar_token=${2:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XGET
    -H "accept: application/json" 
    --data-urlencode domain=$domain
    --data-urlencode recursive=false
    )
    local response=$(avamar_curl api/${apiver}/system/about-information)
    echo $response | jq .
}

# /v1/system/basic-info
function get_avamar_basic-info {
    local apiver=${1:-"v1"}
    local avamar_token=${2:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $avamar_token"
    --data-urlencode domain=$domain
    --data-urlencode recursive=false
    )
    local response=$(avamar_curl api/${apiver}/system/basic-info)
    echo $response | jq .
}

function get_avamar_virtualcenters {
    local cid=${1}
    local domain=${2:-"./"}
    local apiver=${3:-"v1"}
    local avamar_token=${4:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $avamar_token"
    --data-urlencode domain=$domain
    --data-urlencode recursive=false
    )
    local response=$(avamar_curl api/${apiver}/virtualcenters/${cid})
    echo $response | jq '.content[]'
}




function get_avamar_virtualcenters_entities {
    local cid=${1}
    local domain=${2:-"./"}
    local apiver=${3:-"v1"}
    local avamar_token=${4:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $avamar_token"
    --data-urlencode domain=$domain
    --data-urlencode recursive=false
    )
    local response=$(avamar_curl api/${apiver}/virtualcenters/${cid}/entities)
    echo $response | jq '.content[]'
}


function get_avamar_virtualcenters_clients {
    local cid=${1}
    local domain=${2:-"./"}
    local apiver=${3:-"v1"}
    local avamar_token=${4:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $avamar_token"
    --data-urlencode domain=$domain
    --data-urlencode recursive=false
    )
    local response=$(avamar_curl api/${apiver}/virtualcenters/${cid}/clients)
    echo $response | jq '.content[]'
}



# /v1/virtualcenters/{cid}/proxies/recommend
# Recommend Proxies
function get_avamar_virtualcenters_proxies_recommend {
    local cid=${1}
    local datacenter=${2}
    local apiver=${3:-"v1"}
    local avamar_token=${4:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XPOST
    -H "accept: application/json"
    -H "Content-Type: application/json"  
    -H "authorization: Bearer $avamar_token"
    -d '{"backupWindowMins": 720,"changeRate": 0.12,"datacenter": "'${datacenter}'","includeLocalDisks": false}'
    )
    local response=$(avamar_curl api/${apiver}/virtualcenters/${cid}/proxies/recommend)
    echo $response | jq -r .
}
#   # /v1/virtualcenters/{cid}/proxies/{uuid}
# Update Proxy
function update_avamar_proxies {
    local cid=${1}
    local uuid=${2}
    local apiver=${3:-"v1"}
    local avamar_token=${4:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XPUT
    -H "accept: application/json" 
    -H "authorization: Bearer $avamar_token"
    )
    local response=$(avamar_curl api/${apiver}/virtualcenters/${cid}/proxies/${uuid})
    echo $response | jq .
}
function get_avamar_certificates {
    local avamar_token=${1:-$AVAMAR_TOKEN}    
    avi_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $avamar_token"
    --data-urlencode domain=$domain
    --data-urlencode recursive=false
    )
    local response=$(avamar_curl acm/api/keystore/certificates)
    echo $response
}

## /v1/virtualcenters/{cid}/sync
# Sync Virtual Center
function sync_avamar_virtualcenters {
    local cid=${1}
    local uuid=${2}
    local apiver=${3:-"v1"}
    local avamar_token=${4:-$AVAMAR_TOKEN}
    avi_curl_args=(
    -XPOST
    -H "accept: application/json" 
    -H "authorization: Bearer $avamar_token"
    )
    local response=$(avamar_curl api/${apiver}/virtualcenters/${cid}/sync)
    echo $response | jq .
}

function add_avamar_vcenter {
    local avamar_token=${99:-$AVAMAR_TOKEN}
    local vcenter_name=$1
    local vcenter_username=$2
    local vcenter_password=$3
    local domain=$4
    local port=${5:-443}
    local data='{
    "contact": {
        "email": "",
        "phone": "",
        "name": "",
        "location": "",
        "notes": ""
    },
    "name": "'$vcenter_name'",
    "password": "'$vcenter_password'",
    "username": "'$vcenter_username'",
    "port": '$port',
    "domain": "'$domain'",
    "ruleDomainMapping": {},
    "cbtEnabled": false,
    "ruleEnabled": false
}'
    avi_curl_args=(
    -XPOST
    -H "content-type: application/json" 
    -H "authorization: Bearer $avamar_token"
    -d $data    
    )
    local response=$(avamar_curl api/v1/virtualcenters)
    echo $response

}

