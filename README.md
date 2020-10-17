# dps-modules

This Repo contains Task and Functions that can be used in Concourse CI/CD, or any other Automation Solution, from bash

## Requirements
Requires jq to be installed in the calling shell / task /container

## usecase

[functions](./ci/functions) can be sourced locally for testing purposes, and provide Wrappe(s) around curl and ReST API(s)

Currently, parameters are ordered an not checked ( will be part of a later release)

## Examples

Here are some examples for local testing

### PPDM

the PPDM Modules require the FQDN for you PPDM server exported locally as PPDM_FQDN

```bash
export PPDM_FQDN=pp-dr.home.labbuildr.com
```

in order to talk to the api, we need to retrieve a [BEARER] token to talk to the API Endpoints. As we use admin username per default to first setup the appliance, that username is used by default unled PPDM_ADMINUSER is exported in the shell
```bash
source ci/functions/ppdm_functions.sh
# PPDM_TOKEN will use $PPDM_TOKEN as default token
# otherwise a token has to be specified on each call
PPDM_TOKEN=$(get_ppdm_token '<you password admin here>')
```

with a token now exported, we can use the first command:

```bash
get_ppdm_configuration
```

### example scripts

here are some [example scripts](./ci/scripts) leveraging the modules


#### some tasks and tricks

protection_engine=$(get_ppdm_protection-engines | jq -r .id)
proxy=$(get_ppdm_protection-engines_proxies $protection_engine  | jq -r ' .content[] | select(.Config.ProxyType == "External").Id')




#### fresh install

export PPDM_FQDN=52.177.18.170

export PPDM_PASSWORD="Change_Me12345_"
export PPDM_FQDN=40.79.30.118
export PPDM_NTP_SERVER=40.119.6.228

export PPDM_PASSWORD="Change_Me12345_"
 export PPDM_FQDN=40.79.30.118
ping time.windows.com
export PPDM_NTP_SERVER=40.119.6.228
PPDM_TOKEN=$(get_ppdm_token "${PPDM_SETUP_PASSWORD}")



terraform refresh 
source ../../dps-modules/ci/functions/ppdm_functions.sh
export PPDM_PASSWORD="Change_Me12345_"
export PPDM_FQDN=$(terraform output ppdm_public_ip_address)
export PPDM_NTP_SERVER=40.119.6.228
export PPDM_SETUP_PASSWORD=admin
PPDM_TOKEN=$(get_ppdm_token "${PPDM_SETUP_PASSWORD}")
accept_ppdm_eula


CONFIGURATION=$(get_ppdm_configuration)


NODE_ID=$(echo $CONFIGURATION | jq -r .nodeId)  
CONFIGURATION_ID=$(echo $CONFIGURATION | jq -r .id)
echo $CONFIGURATION | jq -r

echo "Customizing Appliance Configuration Template"
CONFIGURATION=$(echo $CONFIGURATION | jq --arg oldpassword changeme --arg password "${PPDM_PASSWORD}" '(.osUsers[] | select(.userName == "root").newPassword) |= $password | (.osUsers[] | select(.userName == "root").password) |= $oldpassword')
CONFIGURATION=$(echo $CONFIGURATION | jq --arg oldpassword '@ppAdm1n' --arg password "${PPDM_PASSWORD}" '(.osUsers[] | select(.userName == "admin").newPassword) |= $password | (.osUsers[] | select(.userName == "admin").password) |= $oldpassword')
CONFIGURATION=$(echo $CONFIGURATION | jq --arg oldpassword '$upp0rt!' --arg password "${PPDM_PASSWORD}" '(.osUsers[] | select(.userName == "support").newPassword) |= $password | (.osUsers[] | select(.userName == "support").password) |= $oldpassword')
CONFIGURATION=$(echo $CONFIGURATION | jq --arg oldpassword 'Ch@ngeme1' --arg password "${PPDM_PASSWORD}" '.lockbox.passphrase  |= $oldpassword | .lockbox.newPassphrase  |= $password')
CONFIGURATION=$(echo $CONFIGURATION | jq --arg password "${PPDM_PASSWORD}" '.applicationUserPassword |= $password')
CONFIGURATION=$(echo $CONFIGURATION | jq --arg timezone "Europe/Berlin - Central European Time" '.timeZone |= $timezone')
CONFIGURATION=$(echo $CONFIGURATION | jq --arg ntpservers "${PPDM_NTP_SERVER}" '.ntpServers |= [$ntpservers]')
CONFIGURATION=$(echo $CONFIGURATION | jq 'del(._links)')


echo $CONFIGURATION | jq -r
