#!/bin/bash
function ppdm_curl {
    local url
    url="https://${PPDM_FQDN}:8443/api/v2/${1#/}"
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
        [[ "${DEBUG}" == "TRUE" ]] && echo $url ${ppdm_curl_args[@]} >&2
        result=$(curl -ks "$url" \
        "${ppdm_curl_args[@]}" "$@"
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



function get_ppdm_token {
    local password=$1
    local ppdm_adminuser=${PPDM_ADMINUSER:-admin}
    ppdm_curl_args=(
    -XPOST    
    -H 'content-type: application/json' 
    -d '{"username":"'${ppdm_adminuser}'","password":"'${password}'"}')
    local response=$(ppdm_curl login  | jq -r '.access_token')
    echo $response
}



function get_ppdm_configuration {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    local response=$(ppdm_curl configurations | jq -r ".content[]" )
    echo $response
}

function get_ppdm_activities {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    local response=$(ppdm_curl activities | jq -r ".content[]" )
    echo $response
}

function get_ppdm_assets {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    local response=$(ppdm_curl assets | jq '.content[]')
    echo $response
}


function get_ppdm_assets_copies {
    local id=${1}
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    local response=$(ppdm_curl assets/${id}/copies | jq '.content')
    echo $response
}


function get_ppdm_copy {
    local id=${1}
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    local response=$(ppdm_curl copies/${id} )
    echo $response
}

function get_ppdm_hosts {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    local response=$(ppdm_curl hosts | jq '.content[]')
    echo $response
}

function get_ppdm_agent-registration-status {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    local response=$(ppdm_curl agent-registration-status | jq -r .) #".content[0]"
    echo $response 
}

function get_ppdm_config_completionstate {
    local token=${99:-$PPDM_TOKEN}
    local configuration_id=${1}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" )
    local response=$(ppdm_curl "configurations/${configuration_id}/config-status" | jq -r '.percentageCompleted' )
    echo $response
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
    local response=$(ppdm_curl "configurations/${configuration_id}" )
    echo $response
}

function get_ppdm_config-status {
    local token=${2:-$PPDM_TOKEN}
    local configuration_id=${1}
    ppdm_curl_args=( 
    -XGET       
    -H "Authorization: Bearer ${token}"
    )
    local response=$(ppdm_curl "configurations/${configuration_id}/config-status"  | jq -r '.status' )
    echo $response
}


function create_ppdm_credentials {
    local token=${99:-$PPDM_TOKEN}
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
    local response=$(ppdm_curl "credentials"  | jq -r . )
    echo $response
    }

function get_ppdm_credentials {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    )
    local response=$(ppdm_curl credentials  | jq '.content[]')
    echo $response
    }    

function get_ppdm_server-disaster-recovery-backups
 {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    )
    local response=$(ppdm_curl server-disaster-recovery-backups  | jq '.content[]')
    echo $response
    }    



function get_ppdm_protection-engines {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    )
    local response=$(ppdm_curl protection-engines  | jq .)
    echo $response
    }

 

function get_ppdm_cloud-dr-accounts {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    )
    local response=$(ppdm_curl cloud-dr-accounts  | jq '.content[]')
    echo $response
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
    local response=$(ppdm_curl inventory-sources  | jq -r . )
    echo $response
}

function get_ppdm_inventory-sources {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    local response=$(ppdm_curl inventory-sources  | jq -r '.content[]')
    echo $response
}

function get_ppdm_locations {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    local response=$(ppdm_curl locations  | jq -r .)
    echo $response
}

function get_ppdm_common-settings {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    local response=$(ppdm_curl common-settings  | jq -r .)
    echo $response
}

function get_ppdm_sdr-settings {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    local response=$(ppdm_curl common-settings/SDR_CONFIGURATION_SETTING  | jq -r .)
    echo $response
}

function set_ppdm_sdr-settings {
    local token=${99:-$PPDM_TOKEN}
    local repositoryHost=${1}
    local repositoryPath=${2}
    local repositoryType=${3}
    local backupsEnabled=${4}
    local id=$(get_ppdm_sdr-settings | jq -r '(.properties[] | select(.name == "configId").value)')
    local data='{
    "backupsEnabled": '$backupsEnabled',
    "id": "'${id}'",
    "repositoryHost": "'${repositoryHost}'",
    "repositoryPath": "'${repositoryPath}'",
    "type": "'${repositoryType}'" 
    }'
    ppdm_curl_args=(
    -XPUT
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    -d "${data}" \
    )  
    local response=$(ppdm_curl server-disaster-recovery-configurations/${id})
    echo $response
}


function send_ppdm_smtp-test {
    local mailFrom=${1}
    local mailServer=${2}
    local password=${3}
    local port=${4}
    local recipient=${5}
    local username=${6}
    local token=${99:-$PPDM_TOKEN}
    local data='{
        "mailFrom": "'${mailFrom}'",
        "mailServer": "'${mailServer}'",
        "password": "'${password}'",
        "port": '${port}',
        "recipient": "'${recipient}'",
        "username": "'${username}'"
        }'
    ppdm_curl_args=(
    -XPOST
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    -d "${data}" \
    )  
    local response=$(ppdm_curl smtp/test)
    echo $response
}


function set_ppdm_smtp_configuration {
    local id=${1}
    local mailFrom=${2}
    local mailServer=${3}
    local password=${4}
    local port=${5}
    local username=${6}
    local token=${99:-$PPDM_TOKEN}
    local data='{
        "id": "'${id}'",
        "mailFrom": "'${mailFrom}'",
        "mailServer": "'${mailServer}'",
        "password": "'${password}'",
        "port": '${port}',
        "username": "'${username}'"
        }'
    ppdm_curl_args=(
    -XPUT
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    -d "${data}" \
    )  
    local response=$(ppdm_curl smtp/${id})
    echo $response
}
function create_ppdm_smtp_configuration {
    local mailFrom=${1}
    local mailServer=${2}
    local password=${3}
    local port=${4}
    local username=${5}
    local token=${99:-$PPDM_TOKEN}
    local data='{
        "mailFrom": "'${mailFrom}'",
        "mailServer": "'${mailServer}'",
        "password": "'${password}'",
        "port": '${port}',
        "username": "'${username}'"
        }'
    ppdm_curl_args=(
    -XPOST
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    -d "${data}" \
    )  
    local response=$(ppdm_curl smtp)
    echo $response
}


function delete_ppdm_smtp_configuration {
    local id=${1}
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XDELETE
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    local response=$(ppdm_curl smtp/${id})
    echo $response
}

function get_ppdm_components {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    local response=$(ppdm_curl components  | jq -r .)
    echo $response
}

function get_ppdm_search-clusters {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    local response=$(ppdm_curl search-clusters  | jq -r .)
    echo $response
}

function get_ppdm_component {
    local id=${1}
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    local response=$(ppdm_curl components/${id}  | jq -r .)
    echo $response
}

function get_ppdm_search-cluster {
    local id=${1}
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    local response=$(ppdm_curl search-clusters/${id}  | jq -r .)
    echo $response
}

function get_ppdm_server-disaster-recovery-hosts {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    local response=$(ppdm_curl server-disaster-recovery-hosts  | jq -r .)
    echo $response
}

function get_ppdm_storage-systems {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    local response=$(ppdm_curl storage-systems  | jq '.content[]')
    echo $response
}

function get_ppdm_telemetry-settings {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    local response=$(ppdm_curl common-settings/TELEMETRY_SETTING  | jq -r .)
    echo $response
}
# /api/v2/smtp
function get_ppdm_smtp-settings {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    )  
    local response=$(ppdm_curl smtp  | jq -r .)
    echo $response
}

function delete_ppdm_inventory-source {
    local token=${2:-$PPDM_TOKEN}
    local inventory_id=${1}
    ppdm_curl_args=(
    -XDELETE
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    )  
    local response=$(ppdm_curl "inventory-sources/${inventory_id}" )
    echo $response
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
    local response=$(ppdm_curl "certificates?host=${host}&port=$port&type=Host")
    echo $response
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
    local response=$(ppdm_curl "certificates/$cert_id" | jq -r .)
    echo $response
    }

function get_ppdm_certificates {
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" 
    )
    local response=$(ppdm_curl certificates)
    echo $response
}

function delete_ppdm_credentials {
    local token=${2:-$PPDM_TOKEN}
    local credentials_id=${1}
    ppdm_curl_args=(
    -XDELETE
    -H "content-type: application/json" 
    -H "Authorization: Bearer ${token}"
    )
    local response=$(ppdm_curl "credentials/${credentials_id}" )
    echo $response
    } 
function start_ppdm-cdr {
    local token=${2:-$PPDM_TOKEN}
    local id=${1}
    ppdm_curl_args=(
    -XPOST    
    -H "content-type: application/json"
    -H "Authorization: Bearer ${token}"
    -d '{"operation":"start"}'
    )  
    local response=$(ppdm_curl "components/${id}/management" )
    echo $response
}
function delete_ppdm_certificate {
    local token=${2:-$PPDM_TOKEN}
    local certificates_id=${1}
    ppdm_curl_args=(
    -XDELETE
    -H "content-type: application/json" 
    -H "Authorization: Bearer ${token}"
    )
    local response=$(ppdm_curl "certificates/${certificates_id}" )
    echo $response 
    }  


function add_ppdm_protection_engine_proxy {
    local protection_engine_id=${1}
    local NetworkMoref=${2}
    local ClusterMoref=${3}
    local DatastoreMoref=${4}
    local FolderMoref=${5}
    local Fqdn=${6}
    local IpAddress=${7}
    local NetMask=${8}
	local Gateway=${9}
	local Dns=${10}
	local IPProtocol=${11}
    local VMName=${12}
    local VimServerRefID=${13}
    local token=${14:-$PPDM_TOKEN}
    local data='{
	"Config": {
		"ProxyType": "External",
		"DeployProxy": true,
		"Port": 9090,
		"Disabled": false,
		"MORef": "",
		"Credential": {
			"Type": "ObjectId"
		},
		"AdvancedOptions": {
			"TransportSessions": {
				"Mode": "HotaddPreferred",
				"UserDefined": true
			}
		},
		"ProxyDeploymentConfig": {
			"Location": {
				"NetworkMoref": "'$NetworkMoref'",
				"ClusterMoref": "'$ClusterMoref'",
				"DatastoreMoref": "'$DatastoreMoref'",
				"FolderMoref": "'$FolderMoref'"
			},
			"Timezone": "",
			"Fqdn": "'$Fqdn'",
			"IpAddress": "'$IpAddress'",
			"NetMask": "'$NetMask'",
			"Gateway": "'$Gateway'",
			"Dns": "'$Dns'",
			"IPProtocol": "'$IPProtocol'",
            "VMName": "'$VMName'"
		},
		"VimServerRef": {
			"Type": "ObjectId",
			"ObjectId": "'$VimServerRefID'"
		},
		"HostName": "'$Fqdn'"
	}
}'
    ppdm_curl_args=(
    -XPOST
    -H "content-type: application/json" \
    -H "Authorization: Bearer ${token}" \
    -d "${data}" \
    )  
    local response=$(ppdm_curl protection-engines/${protection_engine_id}/proxies)
    echo $response
}

function get_ppdm_protection-engines_proxies {
    local id=${1}
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" 
    )
    local response=$(ppdm_curl protection-engines/${id}/proxies)
    echo $response
}


function get_ppdm_protection-engines_proxy {
    local id=${1}
    local proxyId=${2}
    local token=${99:-$PPDM_TOKEN}
    ppdm_curl_args=(
    -XGET
    -H "Authorization: Bearer ${token}" 
    )
    local response=$(ppdm_curl protection-engines/${id}/proxies/${proxyId})
    echo $response
}

function disable_ppdm_protection-engines_proxy {
    local id=${1}
    local proxyId=${2}
    local token=${99:-$PPDM_TOKEN}
    local data=$(get_ppdm_protection-engines_proxy $id $proxyId)
    data=$(echo $data | jq 'del(._links)')
    data=$(echo $data| jq '.Config.Disabled |= true')
    ppdm_curl_args=(
    -XPUT
    -H "content-type: application/json" 
    -H "Authorization: Bearer ${token}" 
    -d "${data}" 
    )
    local response=$(ppdm_curl protection-engines/${id}/proxies/${proxyId})
    echo $response
}

function delete_ppdm_protection-engines_proxy {
    local token=${3:-$PPDM_TOKEN}
    local id=${1}
    local proxyId=${2}
    ppdm_curl_args=(
    -XDELETE
    -H "content-type: application/json" 
    -H "Authorization: Bearer ${token}"
    )
    local response=$(ppdm_curl "protection-engines/${id}/proxies/${proxyId}" )
    echo $response 
    }  


function start_ppdm-instant_restored-copies {
    local copyId=${1}
    local vcenterInventorySourceId=${2}
    local vmName=${3}
    local dataCenterMoref=${4}
    local hostMoref=${5}
    local folderMoref=${6}
    local ref_version=${7}
    local token=${14:-$PPDM_TOKEN}
    local data='{
    "description": "Instant Access Restore",
    "copyId": "'${copyId}'",
    "restoreType": "INSTANT_ACCESS",
    "restoredCopiesDetails": {
      "targetVmInfo": {
        "inventorySourceId": "'${vcenterInventorySourceId}'",
        "vmName": "'$vmName'-'$ref_version'",
        "dataCenterMoref": "'$dataCenterMoref'",
        "clusterMoref": "",
        "folderMoref": "'$folderMoref'",
        "hostMoref": "'$hostMoref'",
        "vmPowerOn": true,
        "vmReconnectNic": false
      }
    }
  }'
    ppdm_curl_args=(
    -XPOST
    -H "content-type: application/json" 
    -H "Authorization: Bearer ${token}"
    -d "${data}" 
    )
    local response=$(ppdm_curl restored-copies)
    echo $response 
    }  

# jq -r .Status.ProxyStatus.Status