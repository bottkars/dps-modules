#!/bin/bash
function ppdd_curl {
    local url
    url="https://${PPDD_FQDN}:3009/rest/v1.0/${1#/}"
    shift || return # fail if we weren't passed at least x args
    local sleep_seconds=10
    local retry=0
    local retries=5
    local result=""
    #while [[ -z $result ]]
    #    do
    #    if [[ $retry -gt $retries ]]
    #        then
    #        echo "exceeded max retries of $retries" >&2
    #        break
   #     fi
    #    [[ "${DEBUG}" == "TRUE" ]] && echo $url ${ppdd_curl_args[@]} >&2
        result=$(curl -ks "$url" \
        "${ppdd_curl_args[@]}" "$@"
        )
    #    [[ "${DEBUG}" == "TRUE" ]] && echo $result >&2
    #    [[ "${DEBUG}" == "TRUE" ]] && echo $retry >&2
     #   ((retry++))
       # if [[ $(echo $result | jq -r 'select(.code != null)' 2> /dev/null) ]]
       #     ### eval section for return code will be added here
       #     then
       #         local errorlevel=$(echo $result | jq -r '.code') 
       #         case $errorlevel in 
       #             400|401)
       #             echo "access denied" >&2
       #             break
       #             ;;
       #             404)
       #             echo "resource does not exist or is deleted" >&2
       #             break
        #            ;;
       #             423)
       #             echo "user locked, waiting for 5 Minutes " >&2
       #             sleep 300
       #             ;;
       #             *)
       #             echo "current State $errorlevel" >&2
       #             ;;
       #         esac    
       #         result=""
       #     [[ "${DEBUG}" == "TRUE" ]] && echo "sleeping for $sleep_seconds seconds" >&2
       #     sleep $sleep_seconds    
        #fi
    #done    
    echo $result
}



function get_ppdd_token {
    local password=$1
    local ppdd_adminuser=${PPDD_ADMINUSER:-sysadmin}
    ppdd_curl_args=(
    -XPOST    
    -H 'content-type: application/json' 
    -d '{"username":"'${ppdd_adminuser}'","password":"'${password}'"}')
    local response=$(ppdd_curl auth)#  | jq -r '.access_token')
    echo $response
}
