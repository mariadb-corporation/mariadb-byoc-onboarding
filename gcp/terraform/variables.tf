variable "project_id" {
  type        = string
  description = "The GCP project ID to deploy resources into."
}

variable "org_id" {
  type        = string
  description = "SkySQL organization id for this account."
}

variable "allowed_regions" {
  type        = list(string)
  description = "GCP regions where SkySQL resources may be created. Drives IAM condition scoping; the first entry is also used as the Google provider's default region."
  validation {
    condition     = length(var.allowed_regions) > 0
    error_message = "allowed_regions must contain at least one region."
  }
}

variable "orchestration_project_id" {
  type        = string
  description = "The GCP project ID hosting MariaDB Cloud's standard service accounts."
}

variable "orchestration_sa_email" {
  type        = string
  description = "The email of the orchestration service account that will be granted permissions. Derived from orchestration_project_id if not set."
  default     = null
}

variable "federated_manager_sa_email" {
  type        = string
  description = "The email of the federated manager service account that will be granted roles/container.admin on SkySQL clusters. Derived from orchestration_project_id if not set."
  default     = null
}

variable "backup_sa_email" {
  type        = string
  description = "The email of the backup service account that will be granted permissions to manage backup service accounts and storage buckets. Derived from orchestration_project_id if not set."
  default     = null
}

# -----------------------------------------------------------------------------
# Terraform state location
#
# These are written by scripts/20-state-backend.sh alongside backend.tf so the two cannot drift.
# -----------------------------------------------------------------------------

variable "state_bucket" {
  type        = string
  description = "GCS bucket holding this deployment's Terraform state. Empty when state is kept locally."
  default     = ""
  validation {
    condition     = var.state_bucket == "" || can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.state_bucket))
    error_message = "state_bucket must be empty or a valid GCS bucket name (3-63 chars, lowercase letters, digits, '.', '_' or '-', starting and ending alphanumeric)."
  }
}

variable "state_prefix" {
  type        = string
  description = "Object prefix within state_bucket. Ignored when state_bucket is empty."
  default     = ""
}
