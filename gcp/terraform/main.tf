# Initial scaffolding for GCP BYOC resources
# Resources will be added in subsequent steps

locals {
  services = toset([
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "file.googleapis.com",
  ])
}

data "google_client_config" "current" {}
data "google_project" "project" {
  project_id = var.project_id
}

resource "google_project_service" "services" {
  for_each           = local.services
  service            = each.value
  project            = var.project_id
  disable_on_destroy = false
}
