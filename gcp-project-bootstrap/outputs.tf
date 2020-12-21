output "project" {
  value = data.google_project.vault.project_id
}

output "region" {
  value = var.region
}