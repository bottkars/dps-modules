#

load functions
```bash
source ci/functions/crda_rest_client.sh
source ci/functions/crds_rest_client.sh 
CDRA_FQDN=cdra.home.labbuildr.com
CDRA_TOKEN=$(get_cdra_token admin 'Password123!')
# get the CDRS  Server
CDRS_FQDN=$(get_cdra_cdrs | jq -r .publicDns)
CDRS_TOKEN=$(get_cdrs_token admin 'Breda1208!')

get_cdrs_vms

get_cdrs_vms_asset_details
# ever wonder where to get a policy of CDRA ??
get_cdrs_client_policies
# what? am i protected 
get_cdrs_protected_vms
```

