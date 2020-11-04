#!/bin/sh
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x




echo "Creating Output"
cat << "EOF" > backend.tf
terraform {
     backend "s3" {}
     }
EOF

echo "Initializing Backend" 
terraform init 
terraform output 



timestamp="$(date '+%Y%m%d.%-H%M.%S')"
export timestamp

OUTPUT_FILE="$(echo "$TFSTATE" | envsubst)" 
echo terraform output  >> terraform-output/${OUTPUT_FILE}

