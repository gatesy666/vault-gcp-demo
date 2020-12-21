provider "google" {
  region  = var.region
  project = "my-project-666666"
}

provider "google-beta" {
  region  = var.region
  project = "my-project-666666"
}

data "google_project" "vault" {
  project_id = "my-project-666666"
}

# Create the vault service account
resource "google_service_account" "vault-server" {
  account_id   = "vault-server"
  display_name = "Vault Server"
  project      = data.google_project.vault.project_id
}

# Add the service account to the project
resource "google_project_iam_member" "service-account" {
  count   = length(var.service_account_iam_roles)
  project = data.google_project.vault.project_id
  role    = element(var.service_account_iam_roles, count.index)
  member  = "serviceAccount:${google_service_account.vault-server.email}"
}

# Add user-specified roles
# resource "google_project_iam_member" "service-account-custom" {
#   count   = length(var.service_account_custom_iam_roles)
#   project = data.google_project.vault.project_id
#   role    = element(var.service_account_custom_iam_roles, count.index)
#   member  = "serviceAccount:${google_service_account.vault-server.email}"
# }

# Enable required services on the project
resource "google_project_service" "service" {
  count   = length(var.project_services)
  project = data.google_project.vault.project_id
  service = element(var.project_services, count.index)

  # Do not disable the service on destroy. On destroy, we are going to
  # destroy the project, but we need the APIs available to destroy the
  # underlying resources.
  disable_on_destroy = false
}

# KMS setup

# Create the KMS key ring
resource "google_kms_key_ring" "vault" {
  name     = "vault"
  location = var.region
  project  = data.google_project.vault.project_id

  depends_on = [google_project_service.service]
}

# Create the crypto key for encrypting init keys
resource "google_kms_crypto_key" "vault-init" {
  name            = "vault-init"
  key_ring        = google_kms_key_ring.vault.id
  rotation_period = "604800s"
}

# Grant service account access to the key
resource "google_kms_crypto_key_iam_member" "vault-init" {
  crypto_key_id = google_kms_crypto_key.vault-init.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.vault-server.email}"
}


# GKE Cluster - Vault

# # VPC
# resource "google_compute_network" "vpc" {
#   name                    = "${data.google_project.vault.project_id}-vpc"
#   auto_create_subnetworks = "false"
# }

# # Subnet
# resource "google_compute_subnetwork" "subnet" {
#   name          = "vault-subnet"
#   region        = var.region
#   network       = google_compute_network.vpc.name
#   ip_cidr_range = "10.10.0.0/24"

# }

# # GKE cluster
# resource "google_container_cluster" "vault" {
#   name     = "vault"
#   location = var.region

#   remove_default_node_pool = true
#   initial_node_count       = 1

#   network    = google_compute_network.vpc.name
#   subnetwork = google_compute_subnetwork.subnet.name

#   master_auth {
#     username = ""
#     password = ""

#     client_certificate_config {
#       issue_client_certificate = false
#     }
#   }
# }

# output "kubernetes_cluster_name" {
#   value       = google_container_cluster.vault.name
#   description = "GKE Cluster Name"
# }

# # Separately Managed Node Pool
# resource "google_container_node_pool" "primary_nodes" {
#   name       = "${google_container_cluster.vault.name}-node-pool"
#   location   = var.region
#   cluster    = google_container_cluster.vault.name
#   node_count = 3

#   node_config {
#     oauth_scopes = [
#       "https://www.googleapis.com/auth/logging.write",
#       "https://www.googleapis.com/auth/monitoring",
#     ]

#     labels = {
#       env = var.project
#     }

#     # preemptible  = true
#     machine_type = "n1-standard-1"
#     tags         = ["vault-node", "${data.google_project.vault.project_id}-vault"]
#     metadata = {
#       disable-legacy-endpoints = "true"
#     }
#     service_account = google_service_account.vault-server.email
#   }
# }










