# -----------------------------------------------------------------------------
# Permission Boundary: EKS Cluster Role (control plane)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "cluster_role_permission_boundary" {
  # EC2 read-only operations required by AmazonEKSClusterPolicy
  statement {
    sid    = "EC2Describe"
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVpcs",
    ]
    resources = ["*"]
  }

  # EC2 ENI operations for VPC Resource Controller
  statement {
    sid    = "EC2ENI"
    effect = "Allow"
    actions = [
      "ec2:AssignPrivateIpAddresses",
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:CreateNetworkInterfacePermission",
      "ec2:DeleteNetworkInterface",
      "ec2:DetachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:UnassignPrivateIpAddresses",
    ]
    resources = ["*"]
  }

  # EC2 security-group mutate — kept wildcarded (EKS auto-creates cluster SG
  # without platform=skysql tag; needs SG tagging prerequisite first)
  statement {
    sid    = "EC2SecurityGroupMutate"
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
    ]
    resources = ["*"]
  }

  # EC2 security-group create — kept wildcarded (EKS creates cluster SG internally)
  statement {
    sid    = "EC2SecurityGroupCreate"
    effect = "Allow"
    actions = [
      "ec2:CreateSecurityGroup",
    ]
    resources = ["*"]
  }

  # EC2 route mutate — restricted to skysql-tagged resources
  statement {
    sid    = "EC2RouteMutate"
    effect = "Allow"
    actions = [
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # EC2 volume create — restricted to requests tagged platform=skysql
  statement {
    sid    = "EC2VolumeCreate"
    effect = "Allow"
    actions = [
      "ec2:CreateVolume",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/platform"
      values   = ["skysql"]
    }
  }

  # EC2 volume mutate — restricted to skysql-tagged resources
  statement {
    sid    = "EC2VolumeMutate"
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
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

  # EC2 ModifyInstanceAttribute — kept wildcarded (VPC Resource Controller uses
  # this; instances may not have platform=skysql tag yet)
  statement {
    sid    = "EC2ModifyInstance"
    effect = "Allow"
    actions = [
      "ec2:ModifyInstanceAttribute",
    ]
    resources = ["*"]
  }

  # EC2 CreateTags on newly-created resources only
  statement {
    sid    = "EC2CreateTagsOnNew"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "CreateNetworkInterface",
        "CreateSecurityGroup",
        "CreateVolume",
      ]
    }
  }

  # EC2 CreateTags on existing skysql-tagged resources
  statement {
    sid    = "EC2CreateTagsExisting"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # Autoscaling read-only
  statement {
    sid    = "AutoscalingDescribe"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
    ]
    resources = ["*"]
  }

  # Autoscaling mutate — restricted to skysql-tagged resources
  statement {
    sid    = "AutoscalingMutate"
    effect = "Allow"
    actions = [
      "autoscaling:UpdateAutoScalingGroup",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # ELB read-only
  statement {
    sid    = "ELBDescribe"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeLoadBalancerPolicies",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
    ]
    resources = ["*"]
  }

  # ELB mutate — kept wildcarded (in-tree cloud provider creates ELBs without
  # platform=skysql; Classic ELB doesn't support tag-based authorization)
  statement {
    sid    = "ELBMutate"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancerListeners",
      "elasticloadbalancing:CreateLoadBalancerPolicy",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancerListeners",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DetachLoadBalancerFromSubnets",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
      "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
    ]
    resources = ["*"]
  }

  # Service-linked roles for ELB
  statement {
    sid    = "ServiceLinkedRole"
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
  }

  # KMS for envelope encryption
  statement {
    sid    = "KMS"
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
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

resource "aws_iam_policy" "cluster_role_permission_boundary" {
  name        = local.cluster_role_boundary_name
  path        = "/"
  description = "Permission boundary for EKS cluster control plane role"
  policy      = data.aws_iam_policy_document.cluster_role_permission_boundary.json
}
