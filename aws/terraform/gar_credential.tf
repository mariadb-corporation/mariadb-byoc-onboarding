# -----------------------------------------------------------------------------
# Permission Boundary: gar-credential-controller
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "gar_credential_permission_boundary" {
  # STS for OIDC/workload-identity federation (IRSA mechanism)
  statement {
    sid    = "STS"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    resources = ["*"]
  }

  # Deny all IAM write — escalation prevention
  statement {
    sid       = "DenyIAMWrite"
    effect    = "Deny"
    actions   = local.deny_iam_write_actions
    resources = ["*"]
  }
}

resource "aws_iam_policy" "gar_credential_permission_boundary" {
  name        = local.gar_credential_boundary_name
  path        = "/"
  description = "Permission boundary for gar-credential-controller role"
  policy      = data.aws_iam_policy_document.gar_credential_permission_boundary.json
}
