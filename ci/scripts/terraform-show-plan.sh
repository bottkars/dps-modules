#!/bin/sh
set -eu
# [[ "${DEBUG}" == "TRUE" ]] && set -x
apk add  gettext \
      figlet > /dev/null 2>&1

figlet DPS Automation
echo "Creating Plan Environment"
mv plan-output-archive/terraform/.t* plan-output-archive/terraform/${STATE_OUTPUT_DIR}/
cd plan-output-archive/terraform/${STATE_OUTPUT_DIR}/
echo "Verifying Plan Envrionment"

terraform show .tfplan
