#!/bin/bash
set -x

vault secrets enable -path=kv2 kv-v2

vault kv put kv2/noddyapp/config username='foo' password='bar'


vault secrets enable pki

vault secrets tune -max-lease-ttl=87600h pki

vault write -field=certificate pki/root/generate/internal common_name="example.com" ttl=87600h

vault write pki/roles/server allow_any_name="true"  max_ttl="720h"



vault policy write noddyapp - <<EOF
path "kv2/*" {
  capabilities = ["read","list"]
}

path "pki/issue/*" {
  capabilities = ["create","update"]
}
EOF

vault write auth/gcpcluster001/role/noddyapp \
        bound_service_account_names=vault-auth\
        bound_service_account_namespaces=default \
        policies=noddyapp \
        ttl=24h