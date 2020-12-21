resource "tls_private_key" "ca" {
  algorithm   = "RSA"
  ecdsa_curve = "P384"
  rsa_bits    = "2048"
}

resource "local_file" "vault_ca_key" {
  content  = tls_private_key.ca.private_key_pem
  filename = "vault_ca_private_key.pem"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm         = tls_private_key.ca.algorithm
  private_key_pem       = tls_private_key.ca.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = 87659

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature"
  ]

  subject {
    organization = "IG"
    common_name  = "IG Private Certificate Authority"
    organizational_unit = "IG"
    country      = "GB"
  }
}

resource "local_file" "vault_ca_cert" {
  content  = tls_self_signed_cert.ca.cert_pem
  filename = "vault_ca_cert.pem"
}

resource "tls_private_key" "vault" {
  algorithm = "RSA"
  ecdsa_curve = "P384"
  rsa_bits  = "4096"
}

resource "local_file" "vault_key" {
  content  = tls_private_key.vault.private_key_pem
  filename = "vault_private_key.pem"
}

resource "tls_cert_request" "vault" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.vault.private_key_pem

  dns_names = ["*.vault-internal"]

  subject {
    common_name         = "*.vault-internal"
    organization        = "multicloud"
    country             = "GB"
    organizational_unit = "IG"
  }
}

resource "tls_locally_signed_cert" "vault" {
  cert_request_pem   = tls_cert_request.vault.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 87659

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

resource "local_file" "vault_cert_pem" {
  content  = tls_locally_signed_cert.vault.cert_pem
  filename = "vault_cert.pem"
}
