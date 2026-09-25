terraform {
  required_version = ">= 1.5, < 2.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.7"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.allowed_regions[0]
}
