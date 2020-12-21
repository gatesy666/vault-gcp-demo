#!/bin/bash
set -x

#Enable vault userpass auth method and Create vault admin user
echo '
path "*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}' | vault policy write vault_admin -
vault auth enable userpass
vault write auth/userpass/users/vault password=vault policies=vault_admin


kubectl create serviceaccount vault-auth

kubectl apply --filename vault-auth-service-account.yaml

# Set VAULT_SA_NAME to the service account you created earlier
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")

# Set SA_JWT_TOKEN value to the service account JWT used to access the TokenReview API
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)

# Set SA_CA_CRT to the PEM encoded CA cert used to talk to Kubernetes API
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

#export K8S_HOST="https://kubernetes.default.svc:443"
export K8S_HOST="https://add app gke cluster address here:443"
#Enable Kubernets auth
vault auth enable -path=gcpcluster001 kubernetes

vault write auth/gcpcluster001/config \
        token_reviewer_jwt="$SA_JWT_TOKEN" \
        kubernetes_host="$K8S_HOST" \
        kubernetes_ca_cert="$SA_CA_CRT"
