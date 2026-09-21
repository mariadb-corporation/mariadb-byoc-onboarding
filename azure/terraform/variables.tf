variable "client_id" {
  type        = string
  description = "The client ID of the trusted external MariaDB Cloud tenant"
}

variable "regions" {
  type        = list(string)
  description = "List of regions for which to create resources."
  default     = ["eastus"]
}

variable "organization_id" {
  type        = string
  description = "The MariaDB Cloud Organization ID."
}
