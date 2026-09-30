# -----------------------------------------------------------------------------
# Permission Boundary: Autoscaler
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "autoscaler_permission_boundary" {
  # Autoscaling read-only actions for cluster-autoscaler
  statement {
    sid    = "AutoscalingDescribe"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
    ]
    resources = ["*"]
  }

  # Autoscaling mutating actions - restricted to SkySQL-tagged resources
  statement {
    sid    = "AutoscalingMutate"
    effect = "Allow"
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # EC2 read-only operations (subset for autoscaler)
  statement {
    sid    = "EC2Describe"
    effect = "Allow"
    actions = [
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetLaunchTemplateData",
    ]
    resources = ["*"]
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

  # Deny all IAM write — escalation prevention
  statement {
    sid       = "DenyIAMWrite"
    effect    = "Deny"
    actions   = local.deny_iam_write_actions
    resources = ["*"]
  }
}

resource "aws_iam_policy" "autoscaler_permission_boundary" {
  name        = local.autoscaler_boundary_name
  path        = "/"
  description = "Permission boundary for cluster autoscaler role"
  policy      = data.aws_iam_policy_document.autoscaler_permission_boundary.json
}
