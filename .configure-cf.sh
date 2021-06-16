#!/usr/bin/env bash

set -e
set -x

# cf create-user user pass
# cf create-org cdcon
# cf create-space prod -o cdcon
# cf create-space staging -o cdcon
# cf set-space-role user cdcon staging SpaceDeveloper
# cf set-space-role user cdcon prod SpaceDeveloper

cf target -o cdcon -s staging
cf_app_domain="$(cf curl /v3/domains | jq -r '.resources[0].name')"
cf_api="$(cf curl /v3/info | jq -r '.links.self.href')"

cat << EOF > secrets.yml
---
cf_username: user
cf_password: pass
cf_api: "$cf_api"
cf_app_domain: "$cf_app_domain"
cf_staging_space: staging
cf_prod_space: prod
cf_org: cdcon
EOF
