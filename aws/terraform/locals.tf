# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  skysql_identities = [
    "arn:aws:iam::${var.orchestration_account_id}:root"
  ]

  orchestration_role_arn = aws_iam_role.skysql_orchestration.arn

  template_version    = "1.0.0"
  metadata_param_name = "/skysql/byoa/metadata"

  # Deployment metadata written to SSM once every other resource succeeds.
  metadata = {
    template_version         = local.template_version
    deployment_method        = "terraform"
    org_id                   = var.org_id
    orchestration_account_id = var.orchestration_account_id
    account_id               = data.aws_caller_identity.current.account_id
    region                   = var.default_region
    orchestration_role_arn   = aws_iam_role.skysql_orchestration.arn
    stack_id                 = null
  }

  # Role-specific permission boundary names
  node_role_boundary_name          = "SkySQL-NodeRole-PermissionBoundary"
  autoscaler_boundary_name         = "SkySQL-Autoscaler-PermissionBoundary"
  lb_controller_boundary_name      = "SkySQL-LBController-PermissionBoundary"
  controller_manager_boundary_name = "SkySQL-ControllerManager-PermissionBoundary"
  cluster_role_boundary_name       = "SkySQL-ClusterRole-PermissionBoundary"
  gar_credential_boundary_name     = "SkySQL-GarCredential-PermissionBoundary"
  backup_boundary_name             = "SkySQL-Backup-PermissionBoundary"

  # Shared deny IAM write actions used across all permission boundaries
  deny_iam_write_actions = [
    "iam:AttachGroupPolicy",
    "iam:AttachRolePolicy",
    "iam:AttachUserPolicy",
    "iam:CreatePolicy",
    "iam:CreatePolicyVersion",
    "iam:CreateRole",
    "iam:CreateUser",
    "iam:DeletePolicy",
    "iam:DeletePolicyVersion",
    "iam:DeleteRole",
    "iam:DeleteRolePermissionsBoundary",
    "iam:DeleteRolePolicy",
    "iam:DeleteUser",
    "iam:DetachGroupPolicy",
    "iam:DetachRolePolicy",
    "iam:DetachUserPolicy",
    "iam:PassRole",
    "iam:PutGroupPolicy",
    "iam:PutRolePermissionsBoundary",
    "iam:PutRolePolicy",
    "iam:PutUserPolicy",
    "iam:UpdateAssumeRolePolicy",
  ]

  # All permission boundary ARNs for IAM policy conditions
  all_permission_boundary_arns = [
    aws_iam_policy.node_role_permission_boundary.arn,
    aws_iam_policy.autoscaler_permission_boundary.arn,
    aws_iam_policy.lb_controller_permission_boundary.arn,
    aws_iam_policy.controller_manager_permission_boundary.arn,
    aws_iam_policy.cluster_role_permission_boundary.arn,
    aws_iam_policy.gar_credential_permission_boundary.arn,
    aws_iam_policy.backup_permission_boundary.arn,
  ]
}
