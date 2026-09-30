# -----------------------------------------------------------------------------
# SSM Parameter: BYOA deployment metadata
#
# Written LAST. depends_on names the policy attachment resource, which
# transitively covers the orchestration role, the seven policies attached to
# it, and the seven permission boundaries (the boundaries are referenced by
# local.all_permission_boundary_arns, consumed by aws_iam_policy.iam). So the
# parameter can only be created once every other resource has succeeded.
#
# This is a diagnostic breadcrumb, not an authoritative record - any account
# admin can edit or delete it. Do not use it as an authz or routing input.
# -----------------------------------------------------------------------------

resource "aws_ssm_parameter" "byoa_metadata" {
  name        = local.metadata_param_name
  type        = "String"
  tier        = "Standard"
  description = "SkySQL BYOA deployment metadata (written last, on success only)"

  # insecure_value rather than value: the payload holds no secrets, and value is
  # schema-sensitive, which would render the plan as "(sensitive value)" and hide
  # from the customer what is being written into their own account.
  insecure_value = jsonencode(local.metadata)

  tags = {
    platform = "skysql"
  }

  depends_on = [aws_iam_role_policy_attachment.skysql_orchestration]
}
