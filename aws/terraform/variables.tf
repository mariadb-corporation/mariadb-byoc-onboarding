variable "orchestration_account_id" {
  description = "AWS Account ID of the SkySQL orchestration account that will assume the skysql-orchestration role"
  type        = string
}

variable "default_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-2"
}

variable "org_id" {
  description = "SkySQL organization id for this account. Copy it verbatim from the SkySQL portal."
  type        = string
}
