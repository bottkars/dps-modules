##


get a token

```bash
AVAMAR_FQDN=avemaster.home.labbuildr.com
AVAMAR_TOKEN=$(get_avamar_token)
```
PROXIES=$(get_avamar_proxies)

VCENTERS=$(get_avamar_virtualcenters)

VCENTER_ID=$(echo $VCENTERS | jq -r  '. | select(.name==env.VCENTER_NAME).cid')