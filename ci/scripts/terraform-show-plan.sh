#!/bin/sh
set -eu
# [[ "${DEBUG}" == "TRUE" ]] && set -x
echo "Creating Plan Envrionment"
mv plan-output-archive/terraform/.t* plan-output-archive/terraform/${STATE_OUTPUT_DIR}/
cd plan-output-archive/terraform/${STATE_OUTPUT_DIR}/
echo "Verifyiing Plan Envrionment"

terrafrom show .tfplan
