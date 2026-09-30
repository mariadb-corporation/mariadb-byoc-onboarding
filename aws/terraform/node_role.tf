# -----------------------------------------------------------------------------
# Permission Boundary: Node Role (node pools)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "node_role_permission_boundary" {
  # EC2 read-only operations (subset for node roles)
  statement {
    sid    = "EC2Describe"
    effect = "Allow"
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVpcs",
    ]
    resources = ["*"]
  }

  # EC2 ENI create
  statement {
    sid    = "EC2ENICreate"
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
    ]
    resources = ["*"]
  }

  # EC2 ENI mutate — restricted to skysql-tagged ENIs
  statement {
    sid    = "EC2ENIMutate"
    effect = "Allow"
    actions = [
      "ec2:AssignPrivateIpAddresses",
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface",
      "ec2:DetachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:UnassignPrivateIpAddresses",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # EC2 CreateTags for CNI - restricted to skysql-tagged network interfaces
  statement {
    sid    = "EC2CreateTagsCNI"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
    ]
    resources = ["arn:aws:ec2:*:*:network-interface/*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # ECR read-only (node role for image pull)
  statement {
    sid    = "ECR"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
    ]
    resources = ["*"]
  }

  # SSM for EKS AMI lookups (node roles)
  statement {
    sid    = "SSM"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
    ]
    resources = [
      "arn:aws:ssm:*::parameter/aws/service/eks/optimized-ami/*"
    ]
  }

  # EKS read-only for workload roles
  statement {
    sid    = "EKS"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
    ]
    resources = ["*"]
  }

  # EBS CSI: mutations on existing SkySQL-tagged volumes/snapshots
  statement {
    sid    = "CSIMutateTagged"
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
      "ec2:DeleteTags",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # EBS CSI: create volumes/snapshots with SkySQL tag
  statement {
    sid    = "CSICreateTagged"
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

  # EBS CSI: create volumes from SkySQL-tagged snapshots
  statement {
    sid    = "CSICreateFromSnapshot"
    effect = "Allow"
    actions = [
      "ec2:CreateVolume",
    ]
    resources = ["arn:aws:ec2:*:*:snapshot/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # Deny all IAM write — escalation prevention
  statement {
    sid       = "DenyIAMWrite"
    effect    = "Deny"
    actions   = local.deny_iam_write_actions
    resources = ["*"]
  }
}

resource "aws_iam_policy" "node_role_permission_boundary" {
  name        = local.node_role_boundary_name
  path        = "/"
  description = "Permission boundary for EKS node pool roles"
  policy      = data.aws_iam_policy_document.node_role_permission_boundary.json
}
