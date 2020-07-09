# dps_modules

This Repo contains Task and Functions that can be used in Concourse CI/CD, or any other Automation Solution, in bash

## Requirements
Requires jq to be installed in the calling shell

## usecase

functions from [./ci/functions] can be sourced locally for testing purposes, and provide Wrappe(s) around curl and ReST API(s)

Currently, parameters are ordered an not checked ( will be part of a later release)

## Examples

Here are Some Examples for local testing

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

example scripts can be found in [./ci/scripts]