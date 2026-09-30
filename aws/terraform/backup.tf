# -----------------------------------------------------------------------------
# Permission Boundary: backup-admin
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "backup_permission_boundary" {
  # STS for OIDC/workload-identity federation (IRSA mechanism)
  statement {
    sid    = "STS"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    resources = ["*"]
  }

  # S3 bucket-level operations for backup buckets
  statement {
    sid    = "S3BucketOperations"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = ["arn:aws:s3:::skysql-backup-*"]
  }

  # S3 object-level operations for backup objects
  statement {
    sid    = "S3ObjectOperations"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::skysql-backup-*/*"]
  }

  # S3 multipart upload operations for large backups
  statement {
    sid    = "S3MultipartOperations"
    effect = "Allow"
    actions = [
      "s3:CreateMultipartUpload",
      "s3:UploadPart",
      "s3:CompleteMultipartUpload",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["arn:aws:s3:::skysql-backup-*/*"]
  }

  # Deny all IAM write — escalation prevention
  statement {
    sid       = "DenyIAMWrite"
    effect    = "Deny"
    actions   = local.deny_iam_write_actions
    resources = ["*"]
  }
}

resource "aws_iam_policy" "backup_permission_boundary" {
  name        = local.backup_boundary_name
  path        = "/"
  description = "Permission boundary for skysql backup admin role"
  policy      = data.aws_iam_policy_document.backup_permission_boundary.json
}
