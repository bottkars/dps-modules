#!/bin/sh
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x
echo "Creating Outputt"
mv plan-output-archive/terraform/.t* plan-output-archive/terraform/${STATE_OUTPUT_DIR}/
cd plan-output-archive/terraform/${STATE_OUTPUT_DIR}/
echo "Verifying Plan Envrionment"

terraform output


sleep 10000 


break exit 1