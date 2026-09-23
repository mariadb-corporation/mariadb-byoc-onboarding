locals {
  template_version = "1.0.0"
  metadata_key     = "skysql-byoc-metadata"

  state_location = var.state_bucket == "" ? null : trimsuffix("gs://${var.state_bucket}/${trim(var.state_prefix, "/")}", "/")

  metadata = {
    template_version         = local.template_version
    deployment_method        = "terraform"
    org_id                   = var.org_id
    orchestration_account_id = var.orchestration_sa_email
    account_id               = var.project_id
    region                   = join(",", var.allowed_regions)
    orchestration_role_arn   = var.orchestration_sa_email
    stack_id                 = local.state_location
  }
}
