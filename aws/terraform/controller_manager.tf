# -----------------------------------------------------------------------------
# Permission Boundary: Controller Manager (skysql-controller-manager)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "controller_manager_permissions" {
  # EC2 read-only operations (volumes/snapshots)
  statement {
    sid    = "EC2Describe"
    effect = "Allow"
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVolumeTypes",
      "ec2:DescribeVolumeStatus",
    ]
    resources = ["*"]
  }

  # EC2 mutations on existing SkySQL-tagged resources
  statement {
    sid    = "EC2MutateTagged"
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:CopySnapshot",
      "ec2:CreateTags",
      "ec2:DeleteSnapshot",
      "ec2:DeleteTags",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:ModifySnapshotAttribute",
      "ec2:ModifyVolume",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # EC2 resource creation - requires SkySQL tag at creation
  statement {
    sid    = "EC2CreateTagged"
    effect = "Allow"
    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/platform"
      values   = ["skysql"]
    }
  }

  # Allow creating volumes from snapshots (only skysql-tagged snapshots)
  statement {
    sid    = "CreateFromSnapshot"
    effect = "Allow"
    actions = [
      "ec2:CreateVolume",
      "ec2:EnableFastSnapshotRestores",
    ]
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # EBS operations
  statement {
    sid    = "EBS"
    effect = "Allow"
    actions = [
      "ebs:ListChangedBlocks",
    ]
    resources = ["*"]
  }

  # S3 access for controller-manager backups
  statement {
    sid    = "S3"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectVersion",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = [
      "arn:aws:s3:::cl-org*",
      "arn:aws:s3:::cl-org*/*",
    ]
  }
}

data "aws_iam_policy_document" "controller_manager_restrictions" {

  # Deny all IAM write — escalation prevention
  statement {
    sid       = "DenyIAMWrite"
    effect    = "Deny"
    actions   = local.deny_iam_write_actions
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "controller_manager_permission_boundary" {
  source_policy_documents = [
    data.aws_iam_policy_document.controller_manager_permissions.json,
    data.aws_iam_policy_document.controller_manager_restrictions.json,
  ]
}

resource "aws_iam_policy" "controller_manager_permission_boundary" {
  name        = local.controller_manager_boundary_name
  path        = "/"
  description = "Permission boundary for skysql-controller-manager role"
  policy      = data.aws_iam_policy_document.controller_manager_permission_boundary.json
}
