output "project_id" {
  description = "The GCP project MariaDB BYOC was enabled in."
  value       = var.project_id
}

output "project_number" {
  description = "The numeric ID of the project."
  value       = data.google_project.project.number
}

output "allowed_regions" {
  description = "Regions MariaDB may create resources in."
  value       = var.allowed_regions
}

output "state_location" {
  description = "Where this deployment's Terraform state is stored, or null when it is kept locally."
  value       = local.state_location
}

output "metadata_key" {
  description = "Project metadata key holding the BYOC deployment metadata."
  value       = local.metadata_key
}

output "byoc_metadata" {
  description = "The BYOC deployment metadata written to project metadata."
  value       = local.metadata
}
