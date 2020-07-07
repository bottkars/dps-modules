#!/bin/bah

function get_token {
    local password=$1
    local TOKEN=$(curl -k -sS --request POST \
    --connect-timeout 10 \
    --max-time 10 \
    --retry 3 \
    --retry-delay 5 \
    --retry-max-time 40 \
    --url "https://${PPDM_FQDN}:8443/api/v2/login" -k \
    --header 'content-type: application/json' \
    --data '{"username":"admin","password":"'${password}'"}' | jq -r .access_token )

}



