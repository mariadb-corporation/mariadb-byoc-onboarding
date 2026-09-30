# -----------------------------------------------------------------------------
# Permission Boundary: LB Controller
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "lb_controller_permission_boundary" {
  # ELB read-only operations
  statement {
    sid    = "ELBDescribe"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeListenerAttributes",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
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

  # ELB create operations — require platform=skysql tag on creation request
  statement {
    sid    = "ELBCreate"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/platform"
      values   = ["skysql"]
    }
  }

  # ELB mutate operations — only on resources tagged platform=skysql
  statement {
    sid    = "ELBMutate"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # ELB listener/rule and target registration operations
  # These sub-resources don't consistently support tag-based authorization
  statement {
    sid    = "ELBListenerOps"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
    ]
    resources = ["*"]
  }

  # ELB AddTags during resource creation
  statement {
    sid    = "ELBTagOnNew"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddTags",
    ]
    resources = [
      "arn:*:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:*:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:*:elasticloadbalancing:*:*:loadbalancer/app/*/*",
      "arn:*:elasticloadbalancing:*:*:listener/*/*/*/*",
      "arn:*:elasticloadbalancing:*:*:listener-rule/*/*/*/*/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "elasticloadbalancing:CreateAction"
      values   = ["CreateTargetGroup", "CreateLoadBalancer", "CreateListener", "CreateRule"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/platform"
      values   = ["skysql"]
    }
  }

  # ELB AddTags/RemoveTags on existing tagged resources
  statement {
    sid    = "ELBTagExisting"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:RemoveTags",
    ]
    resources = [
      "arn:*:elasticloadbalancing:*:*:targetgroup/*/*",
      "arn:*:elasticloadbalancing:*:*:loadbalancer/net/*/*",
      "arn:*:elasticloadbalancing:*:*:loadbalancer/app/*/*",
      "arn:*:elasticloadbalancing:*:*:listener/*/*/*/*",
      "arn:*:elasticloadbalancing:*:*:listener-rule/*/*/*/*/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # EC2 read-only operations (subset for LB controller)
  statement {
    sid    = "EC2Describe"
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeCoipPools",
      "ec2:DescribeInstances",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeVpcs",
      "ec2:GetCoipPoolUsage",
    ]
    resources = ["*"]
  }

  # EC2 security group operations for LB controller
  statement {
    sid    = "EC2SecurityGroupMutate"
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:DeleteSecurityGroup",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # EC2 security group creation with tag conditions
  statement {
    sid    = "EC2SecurityGroupCreate"
    effect = "Allow"
    actions = [
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
    ]
    resources = [
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:vpc/*",
    ]
  }

  # CreateTags on existing tagged resources
  statement {
    sid    = "EC2TagExisting"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # Service-linked roles for ELB (lb-controller)
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

  # Deny all IAM write — escalation prevention
  statement {
    sid       = "DenyIAMWrite"
    effect    = "Deny"
    actions   = local.deny_iam_write_actions
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lb_controller_permission_boundary" {
  name        = local.lb_controller_boundary_name
  path        = "/"
  description = "Permission boundary for AWS Load Balancer Controller role"
  policy      = data.aws_iam_policy_document.lb_controller_permission_boundary.json
}
