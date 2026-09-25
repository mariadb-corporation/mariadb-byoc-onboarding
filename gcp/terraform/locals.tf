locals {
  template_version = "1.0.0"
  metadata_key     = "skysql-byoc-metadata"

  state_location = var.state_bucket == "" ? null : trimsuffix("gs://${var.state_bucket}/${trim(var.state_prefix, "/")}", "/")

  # MariaDB Cloud's standard service account names, used to derive their emails
  # from orchestration_project_id when an explicit override isn't given.
  # orchestration_project_id is a required prompt; "" means "not using this".
  orchestration_project_id_set = var.orchestration_project_id != ""

  orchestration_sa_email = coalesce(
    var.orchestration_sa_email,
    local.orchestration_project_id_set ? "skysql-orchestration@${var.orchestration_project_id}.iam.gserviceaccount.com" : null
  )
  federated_manager_sa_email = coalesce(
    var.federated_manager_sa_email,
    local.orchestration_project_id_set ? "skysql-federated-manager@${var.orchestration_project_id}.iam.gserviceaccount.com" : null
  )
  backup_sa_email = coalesce(
    var.backup_sa_email,
    local.orchestration_project_id_set ? "backup-service@${var.orchestration_project_id}.iam.gserviceaccount.com" : null
  )

  # The GCP project hosting the orchestration service account.
  orchestration_account_id = local.orchestration_project_id_set ? var.orchestration_project_id : split(".", split("@", local.orchestration_sa_email)[1])[0]

  metadata = {
    template_version         = local.template_version
    deployment_method        = "terraform"
    org_id                   = var.org_id
    orchestration_account_id = local.orchestration_account_id
    account_id               = var.project_id
    region                   = join(",", var.allowed_regions)
    orchestration_role_arn   = local.orchestration_sa_email
    stack_id                 = local.state_location
  }
}

check "service_account_emails_configured" {
  assert {
    condition = (
      local.orchestration_project_id_set
      ) || (
      var.orchestration_sa_email != null &&
      var.federated_manager_sa_email != null &&
      var.backup_sa_email != null
    )
    error_message = "Set orchestration_project_id, or all three of orchestration_sa_email/federated_manager_sa_email/backup_sa_email."
  }
}
