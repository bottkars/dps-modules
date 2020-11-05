#!/bin/sh
set -eu
[[ "${DEBUG}" == "TRUE" ]] && set -x

apk add  gettext \
      figlet > /dev/null 2>&1

figlet DPS Automation
echo "Creating Output"
cat << "EOF" > backend.tf
terraform {
     backend "s3" {}
}
EOF

echo "Initializing Backend" 
terraform init -input=false \
    -backend-config=force_path_style=${TF_BACKEND_CONFIG_force_path_style} \
    -backend-config=access_key=${TF_BACKEND_CONFIG_access_key} \
    -backend-config=skip_region_validation=${TF_BACKEND_CONFIG_skip_region_validation} \
    -backend-config=skip_metadata_api_check=true \
    -backend-config=endpoint=${TF_BACKEND_CONFIG_endpoint} \
    -backend-config=bucket=${TF_BACKEND_CONFIG_bucket} \
    -backend-config=skip_credentials_validation=true \
    -backend-config=key=${TF_BACKEND_CONFIG_key} \
    -backend-config=secret_key=${TF_BACKEND_CONFIG_secret_key} \
    -backend-config=region=${TF_BACKEND_CONFIG_region} .
echo "Refreshing current State"
terraform refresh
terraform output 

timestamp="$(date '+%Y%m%d.%-H%M.%S')"
export timestamp


OUTPUT_FILE="$(echo "$TFSTATE" | envsubst)" 
echo terraform output  >> terraform-output/${OUTPUT_FILE}