#!/bin/bash
# Function Set for ddve on vsphere


function avi-cli-run {
    local command=$@
    local shell="/bin/bash -c"
    govc guest.run -vm.ipath "${GOVC_VM_IPATH}" \
    -l "${AVE_USERNAME}:${AVE_PASSWORD}" \
    ${shell} \
    "\"source /etc/profile.local; avi-cli ${command}\"" 
}    

function avi-cli-start {
    local command=$@
    local shell="/bin/bash -c"
    govc guest.start -vm.ipath "${GOVC_VM_IPATH}" \
    -l "${AVE_USERNAME}:${AVE_PASSWORD}" \
    ${shell} \
    "\"source /etc/profile.local; avi-cli ${command}\"" 
} 


function avi-run-bashscript {
    local command=$@
    local shell="/bin/bash -c"
    govc guest.run -vm.ipath "${GOVC_VM_IPATH}" \
    -l "${AVE_USERNAME}:${AVE_PASSWORD}" \
    ${shell} \
    "\"source /etc/profile.local; ${command}\"" 
} 

function avi-start-bashscript {
    local command=$@
    local shell="/bin/bash -c"
    govc guest.start -vm.ipath "${GOVC_VM_IPATH}" \
    -l "${AVE_USERNAME}:${AVE_PASSWORD}" \
    ${shell} \
    "\"source /etc/profile.local; ${command}\"" 
} 


### rest functions
function avi_curl {
    local url
    local avi_fqdn=${AVE_FQDN:-AVI_FQDN}
    url="https://${avi_fqdn}:7543/avi/service/api/${1#/}"
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
    echo $result | jq -e . 2>/dev/null
}

function get_avi_token {
    local password=$1
    local avi_adminuser=${AVE_ROOT:-root}
    avi_curl_args=(
    -XPOST    
    -H 'content-type: application/json' 
    -d '{"username":"'${avi_adminuser}'","password":"'${password}'"}')
    local response=$(avi_curl security/login  | jq -r '.token')
    echo $response
}

function get_avi_packages {
    local token=${99:-$AVI_TOKEN}
    avi_curl_args=(
    -XGET  
    -H 'content-type: application/json' 
    -b "JSESSIONID=${token}" )
    local response=$(avi_curl packages  | jq -r '.packages[]')
    echo $response
}


function get_avi_packages_history {
    local token=${99:-$AVI_TOKEN}
    avi_curl_args=(
    -XGET  
    -H 'content-type: application/json' 
    -b "JSESSIONID=${token}" )
    local response=$(avi_curl packages/history  | jq -r .histories )
    echo $response
}



packages/install/



function get_avi_userinput {
    local package=$1
    local token=${99:-$AVI_TOKEN}
    local avi_adminuser=${AVE_ROOT:-root}
    avi_curl_args=(
    -XGET
    -H 'content-type: text/plain' 
    -b "JSESSIONID=${token}" 
    )
    local response=$(avi_curl userinput/$package  )
    echo $response
}

function set_avi_config {
    local data=$1
    local package=$2
    local token=${99:-$AVI_TOKEN}
    local avi_adminuser=${AVE_ROOT:-root}
    avi_curl_args=(
    -XPOST
    -v    
    -H 'content-type: multipart/form-data' 
    -b "JSESSIONID=${token}"
    -F userinput="" 
    -F input=${data}
    )
    local response=$(avi_curl packages/install/$package  | jq -r '.token')
    echo $response
}


function get_avi_messages {
    local token=${99:-$AVI_TOKEN}
    local avi_adminuser=${AVE_ROOT:-root}
    avi_curl_args=(
    -XGET
    -H 'content-type: application/json' 
    -b "JSESSIONID=${token}" 
    )
    local response=$(avi_curl messages  | jq -r '.messages')
    echo $response
}
