#!/bin/bash
# Function Set CDRA
# https://cdra.home.labbuildr.com/swagger-ui.html

function cdra_curl {
    local url
    local cdra_fqdn=${CDRA_FQDN}
    url="https://${cdra_fqdn}/${1#/}"
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
        [[ "${DEBUG}" == "TRUE" ]] && echo $url ${cdra_curl_args[@]} >&2
        result=$(curl -ks "$url" \
        "${cdra_curl_args[@]}" "$@"
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
    echo $result  | jq -e . 2>/dev/null
}




function get_cdra_token {
    local cdra_user=${1}
    local cdra_password=${2:-$CDRA_PASSWORD}
    cdra_curl_args=(
    -XPOST
    -H 'content-type: application/x-www-form-urlencoded' 
    --data-urlencode "grant_type=password"
    --data-urlencode "scope=write"
    --data-urlencode "username=$cdra_user"
    --data-urlencode "password=$cdra_password"
)
    local response=$(cdra_curl rest/oauth2/token/swagger)
    echo $response | jq -r '.access_token'
}

#    -F "username=root"
#    -F 'vcenter=null'
#    -F 'scope=all'
#    -F 'domain=%F2'
#    -F 'type=cdra'
#    -F "password=Change_Me12345_"
#grant_type=password&scope=all&username=root&domain=%2F&type=cdra&vcenter=null&password=Change_Me12345_




function create_cdra_oauth_client {
    cdra_curl_args=(
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
    local response=$(cdra_curl api/v1/oauth2/clients  | jq -r '.')
    echo $response
}





function get_cdra_copies_catalog {
    local cdra_token=${1:-$CDRA_TOKEN}
    cdra_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $cdra_token"
    )
    local response=$(cdra_curl /rest/v2/copies-catalog)
    echo $response
}




function get_cdra_copies_storage {
    local cdra_token=${1:-$CDRA_TOKEN}
    cdra_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $cdra_token"
    )
    local response=$(cdra_curl /rest/v2/copies-storage)
    echo $response
}

function get_cdra_vms {
    local cdra_token=${1:-$CDRA_TOKEN}
    cdra_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $cdra_token"
    )
    local response=$(cdra_curl /rest/vms)
    echo $response
}


function get_cdra_client_policies {
    local cdra_token=${1:-$CDRA_TOKEN}
    cdra_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $cdra_token"
    )
    local response=$(cdra_curl /rest/v2/client-policies)
    echo $response
}

# 
# /rest/cloudAccounts
function get_cdra_cloudAccounts {
    local cdra_token=${1:-$CDRA_TOKEN}
    cdra_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $cdra_token"
    )
    local response=$(cdra_curl /rest/v2/cloudAccounts)
    echo $response
}

# /rest/v2/cloud-accounts/cloud-targets
function get_cdra_cloud_targets {
    local cdra_token=${1:-$CDRA_TOKEN}
    cdra_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $cdra_token"
    )
    local response=$(cdra_curl /rest/v2/cloud-accounts/cloud-targets)
    echo $response
}

# /rest/v2/cloud-operations/cdrs/instance

function get_cdra_cdrs_instance {
    local cdra_token=${1:-$CDRA_TOKEN}
    cdra_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $cdra_token"
    )
    local response=$(cdra_curl /rest/v2/cloud-operations/cdrs/instance)
    echo $response
}
# /rest/v2/cloud-operations/cdrs

function get_cdra_cdrs {
    local cdra_token=${1:-$CDRA_TOKEN}
    cdra_curl_args=(
    -XGET
    -H "accept: application/json" 
    -H "authorization: Bearer $cdra_token"
    )
    local response=$(cdra_curl /rest/v2/cloud-operations/cdrs)
    echo $response
}
