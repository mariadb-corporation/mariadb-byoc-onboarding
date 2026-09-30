# -----------------------------------------------------------------------------
# skysql-orchestration IAM Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "skysql_orchestration" {
  name = "skysql-orchestration"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [ {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Principal": {
            "AWS": ${jsonencode(local.skysql_identities)}
        }
    } ]
}
EOF

  tags = {
    platform                    = "skysql"
    "skysql:metadata-region"    = var.default_region
    "skysql:metadata-parameter" = local.metadata_param_name
    "skysql:deployment-method"  = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Policy: Networking (VPC, subnets, gateways, routes, security groups, EIPs)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "networking" {
  # 1. Describe — no tag condition required
  statement {
    sid    = "Describe"
    effect = "Allow"
    actions = [
      "ec2:DescribeAddresses",
      "ec2:DescribeAddressesAttribute",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeNatGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribePrefixLists",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcEndpoints",
      "ec2:DescribeVpcEndpointServiceConfigurations",
      "ec2:DescribeVpcEndpointServicePermissions",
      "ec2:DescribeVpcEndpointServices",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcEndpointConnections",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "kms:ListKeys",
    ]
    resources = ["*"]
  }

  # 2. Create taggable resources — must include platform=skysql tag at creation
  statement {
    sid    = "CreateTaggable"
    effect = "Allow"
    actions = [
      "ec2:AllocateAddress",
      "ec2:CreateInternetGateway",
      "ec2:CreateNetworkInterface",
      "ec2:CreateVpc",
      "ec2:CreateVpcEndpointServiceConfiguration",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/platform"
      values   = ["skysql"]
    }
  }

  # 3. Create actions that don't support RequestTag conditions
  statement {
    sid    = "CreateUnrestricted"
    effect = "Allow"
    actions = [
      "ec2:CreateNatGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateVpcEndpoint",
    ]
    resources = ["*"]
  }

  # 4a. CreateTags on newly created resources (during create actions)
  statement {
    sid    = "CreateTagsOnNew"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "AllocateAddress",
        "CreateInternetGateway",
        "CreateNatGateway",
        "CreateNetworkInterface",
        "CreateRouteTable",
        "CreateSecurityGroup",
        "CreateSubnet",
        "CreateVpc",
        "CreateVpcEndpoint",
        "CreateVpcEndpointServiceConfiguration",
        "CreateLaunchTemplate",
        "CreateAutoScalingGroup",
        "RunInstances",
      ]
    }
  }

  # 4b. CreateTags/DeleteTags on existing tagged resources
  statement {
    sid    = "CreateDeleteTagsOnExisting"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # Allow tagging existing snapshots
  statement {
    sid    = "TagExistingSnapshots"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
    ]
    resources = ["arn:aws:ec2:*::snapshot/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # 5. Mutate/delete actions — only on resources tagged platform=skysql
  statement {
    sid    = "MutateDeleteTagged"
    effect = "Allow"
    actions = [
      "ec2:AssociateAddress",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteNatGateway",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteVpc",
      "ec2:DeleteVpcEndpoints",
      "ec2:DeleteVpcEndpointServiceConfigurations",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateAddress",
      "ec2:DisassociateRouteTable",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:ModifyVpcEndpoint",
      "ec2:ModifyVpcEndpointServicePermissions",
      "ec2:ReleaseAddress",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
      "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
      "ec2:TerminateInstances",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/platform"
      values   = ["skysql"]
    }
  }
}

resource "aws_iam_policy" "networking" {
  name        = "SkySQL-Networking-Policy"
  path        = "/"
  description = "Grants SkySQL access for VPC and networking provisioning"
  policy      = data.aws_iam_policy_document.networking.json
}

# -----------------------------------------------------------------------------
# Policy: EKS (clusters access entries)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "eks" {

  statement {
    sid    = "ListClustersOnly"
    effect = "Allow"
    actions = [
      "eks:ListClusters",
      "eks:DescribeAddonVersions",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllEKSActions"
    effect = "Allow"
    actions = [
      "eks:CreateCluster",
      "eks:TagResource",
      "eks:DescribeCluster",
      "eks:CreateAccessEntry",
      "eks:DescribeAccessEntry",
      "eks:AssociateAccessPolicy",
      "eks:DisassociateAccessPolicy",
      "eks:ListAssociatedAccessPolicies",
      "eks:DeleteCluster",
      "eks:UpdateClusterConfig",
      "eks:UpdateClusterVersion",
      "eks:DescribeUpdate",
      "eks:UntagResource",
      "eks:ListTagsForResource",
      "eks:DeleteAccessEntry",
      "eks:UpdateAccessEntry",
      "eks:ListAccessEntries",
      "eks:ListAccessPolicies",
      "eks:CreateAddon",
      "eks:DescribeAddon",
      "eks:UpdateAddon",
      "eks:DeleteAddon",
      "eks:ListAddons",
    ]
    resources = [
      "arn:aws:eks:*:${data.aws_caller_identity.current.account_id}:cluster/cl-org*",
      "arn:aws:eks:*:${data.aws_caller_identity.current.account_id}:access-entry/cl-org*",
      "arn:aws:eks:*:${data.aws_caller_identity.current.account_id}:addon/cl-org*",
    ]
  }
}

resource "aws_iam_policy" "eks" {
  name        = "SkySQL-EKS-Policy"
  path        = "/"
  description = "Grants SkySQL access for EKS cluster provisioning"
  policy      = data.aws_iam_policy_document.eks.json
}

# -----------------------------------------------------------------------------
# Policy: Compute (EC2 instances, launch templates, EBS, autoscaling)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "compute" {
  # 1. Describe — no tag condition required
  statement {
    sid    = "Describe"
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeInstanceRefreshes",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeLifecycleHooks",
      "autoscaling:DescribeLoadBalancerTargetGroups",
      "autoscaling:DescribeLoadBalancers",
      "autoscaling:DescribeNotificationConfigurations",
      "autoscaling:DescribePolicies",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeScheduledActions",
      "autoscaling:DescribeTags",
      "ec2:DescribeTags",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetLaunchTemplateData",
      "ec2:DescribeVolumes",
      "ec2:DescribeInstanceStatus",
    ]
    resources = ["*"]
  }

  # 2. Create taggable resources — must include platform=skysql tag at creation
  statement {
    sid    = "CreateTaggable"
    effect = "Allow"
    actions = [
      "autoscaling:CreateAutoScalingGroup",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateVolume",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/platform"
      values   = ["skysql"]
    }
  }

  statement {
    sid    = "RunInstances"
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
    ]
    resources = ["*"]
  }

  # 4. Mutate/delete actions — only on resources tagged platform=skysql
  statement {
    sid    = "MutateDeleteTagged"
    effect = "Allow"
    actions = [
      "autoscaling:AttachInstances",
      "autoscaling:CreateOrUpdateTags",
      "autoscaling:DeleteAutoScalingGroup",
      "autoscaling:DeleteTags",
      "autoscaling:DetachInstances",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:SuspendProcesses",
      "autoscaling:UpdateAutoScalingGroup",
      "ec2:CreateLaunchTemplateVersion",
      "ec2:DeleteLaunchTemplate",
      "ec2:DeleteLaunchTemplateVersions",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:ModifyLaunchTemplate",
      "ec2:GetConsoleOutput",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/platform"
      values   = ["skysql"]
    }
  }

  # 5. SSM Parameter access for EKS AMI lookup
  statement {
    sid    = "SSMParameterRead"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
    ]
    resources = [
      "arn:aws:ssm:*::parameter/aws/service/eks/optimized-ami/*"
    ]
  }

  # 6. Read the BYOA deployment metadata written by this stack. Kept separate
  # from the statement above so GetParameterHistory is not widened onto the
  # public EKS AMI parameters.
  statement {
    sid    = "SSMMetadataRead"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterHistory",
    ]
    resources = [
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter${local.metadata_param_name}"
    ]
  }
}

resource "aws_iam_policy" "compute" {
  name        = "SkySQL-Compute-Policy"
  path        = "/"
  description = "Grants SkySQL access for EC2 and autoscaling provisioning"
  policy      = data.aws_iam_policy_document.compute.json
}

# -----------------------------------------------------------------------------
# Policy: IAM (roles, policies, instance profiles, OIDC providers)
# Scoped with path restriction + permission boundary enforcement
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "iam" {
  # Read-only IAM operations
  statement {
    sid    = "IAMReadOnly"
    effect = "Allow"
    actions = [
      "iam:GetInstanceProfile",
      "iam:GetOpenIDConnectProvider",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfiles",
      "iam:ListInstanceProfilesForRole",
      "iam:ListInstanceProfileTags",
      "iam:ListOpenIDConnectProviders",
      "iam:ListOpenIDConnectProviderTags",
      "iam:ListPolicies",
      "iam:ListPolicyVersions",
      "iam:ListPolicyTags",
      "iam:ListRolePolicies",
      "iam:ListRoles",
      "iam:ListRoleTags",
    ]
    resources = ["*"]
  }

  # Create roles only under /skysql/ path and only with one of the permission boundaries
  statement {
    sid    = "CreateRoleWithBoundary"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/skysql/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = local.all_permission_boundary_arns
    }
  }

  # Create roles only under /skysql/ path and only with the permission boundary
  statement {
    sid    = "TagRolesWithBoundary"
    effect = "Allow"
    actions = [
      "iam:TagRole",
      "iam:UntagRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/skysql/*",
    ]
  }

  # Delete roles under /skysql/ path
  statement {
    sid    = "DeleteRole"
    effect = "Allow"
    actions = [
      "iam:DeleteRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/skysql/*",
    ]
  }

  # Update trust policy on roles under /skysql/ path
  statement {
    sid    = "UpdateTrustPolicy"
    effect = "Allow"
    actions = [
      "iam:UpdateAssumeRolePolicy",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/skysql/*",
    ]
  }

  # Manage policies under /skysql/ path
  statement {
    sid    = "ManagePolicies"
    effect = "Allow"
    actions = [
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/skysql/*",
    ]
  }

  # Attach/detach policies on roles under /skysql/ path
  statement {
    sid    = "AttachDetachPolicies"
    effect = "Allow"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/skysql/*",
    ]
  }

  # Inline policies on roles under /skysql/ path
  statement {
    sid    = "InlinePolicies"
    effect = "Allow"
    actions = [
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/skysql/*",
    ]
  }

  # Instance profiles under /skysql/ path
  statement {
    sid    = "ManageInstanceProfiles"
    effect = "Allow"
    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/skysql/*",
    ]
  }

  # PassRole restricted to /skysql/ path
  statement {
    sid    = "PassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/skysql/*",
    ]
  }

  # OIDC providers restricted to EKS issuers
  statement {
    sid    = "OIDCProvider"
    effect = "Allow"
    actions = [
      "iam:CreateOpenIDConnectProvider",
      "iam:DeleteOpenIDConnectProvider",
      "iam:GetOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider",
      "iam:UntagOpenIDConnectProvider",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.*.amazonaws.com/*",
    ]
  }

  # Service-linked roles for Auto Scaling, ELB, and EKS
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
      values = [
        "autoscaling.amazonaws.com",
        "elasticloadbalancing.amazonaws.com",
        "eks.amazonaws.com",
      ]
    }
  }

  # DENY: Prevent modification of any permission boundary policy
  statement {
    sid    = "DenySelfEscalation"
    effect = "Deny"
    actions = [
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
    ]
    resources = local.all_permission_boundary_arns
  }

  # DENY: Prevent modification of the orchestration role itself
  statement {
    sid    = "DenyOrchestratorModification"
    effect = "Deny"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:UpdateAssumeRolePolicy",
    ]
    resources = [
      local.orchestration_role_arn,
    ]
  }

  # Allow setting permission boundaries only to approved boundaries
  statement {
    sid    = "AllowSetApprovedBoundary"
    effect = "Allow"
    actions = [
      "iam:PutRolePermissionsBoundary",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values   = local.all_permission_boundary_arns
    }
  }

  # DENY: Prevent removing permission boundary on created roles
  statement {
    sid    = "DenyRemoveBoundary"
    effect = "Deny"
    actions = [
      "iam:DeleteRolePermissionsBoundary",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/skysql/*",
    ]
  }

  # DENY: Prevent creating roles without one of the required permission boundaries
  statement {
    sid    = "DenyCreateRoleWithoutBoundary"
    effect = "Deny"
    actions = [
      "iam:CreateRole",
    ]
    resources = ["*"]
    condition {
      test     = "ForAllValues:StringNotEquals"
      variable = "iam:PermissionsBoundary"
      values   = local.all_permission_boundary_arns
    }
  }
}

resource "aws_iam_policy" "iam" {
  name        = "SkySQL-IAM-Policy"
  path        = "/"
  description = "Grants SkySQL access for IAM role and policy management"
  policy      = data.aws_iam_policy_document.iam.json
}

# -----------------------------------------------------------------------------
# Policy: Storage (S3, DynamoDB, EFS)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "storage" {
  statement {
    sid    = "S3BucketManagement"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:DeleteBucketPolicy",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketTagging",
      "s3:PutLifecycleConfiguration",
      "s3:GetBucketAcl",
      "s3:GetBucketCORS",
      "s3:GetBucketLogging",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketTagging",
      "s3:GetBucketVersioning",
      "s3:GetEncryptionConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
    ]
    resources = [
      "arn:aws:s3:::cl-org*",
      "arn:aws:s3:::skysql-backup*",
    ]
  }

  statement {
    sid    = "S3ObjectManagement"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = [
      "arn:aws:s3:::cl-org*/*",
      "arn:aws:s3:::skysql-backup*/*",
    ]
  }

  statement {
    sid    = "S3ListBuckets"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "DynamoDB"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:CreateTable",
      "dynamodb:DeleteItem",
      "dynamodb:DeleteTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:ListTagsOfResource",
    ]
    resources = [
      "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/skysql-terraform-state-lock",
    ]
  }
}

resource "aws_iam_policy" "storage" {
  name        = "SkySQL-Storage-Policy"
  path        = "/"
  description = "Grants SkySQL access for S3, DynamoDB, and EFS"
  policy      = data.aws_iam_policy_document.storage.json
}

# -----------------------------------------------------------------------------
# Policy: Load Balancing (ELB, ALB, NLB)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "loadbalancing" {
  statement {
    sid    = "Describe"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "loadbalancing" {
  name        = "SkySQL-LoadBalancer-Policy"
  path        = "/"
  description = "Grants SkySQL access for ELB/ALB/NLB provisioning"
  policy      = data.aws_iam_policy_document.loadbalancing.json
}

resource "aws_iam_policy" "disk" {
  name        = "SkySQL-DiskVolume-Policy"
  path        = "/"
  description = "Grants SkySQL access for EBS operations"
  policy      = data.aws_iam_policy_document.controller_manager_permissions.json
}

# -----------------------------------------------------------------------------
# Attach all policies to the role
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "skysql_orchestration" {
  for_each = {
    networking    = aws_iam_policy.networking.arn
    eks           = aws_iam_policy.eks.arn
    compute       = aws_iam_policy.compute.arn
    iam           = aws_iam_policy.iam.arn
    storage       = aws_iam_policy.storage.arn
    loadbalancing = aws_iam_policy.loadbalancing.arn
    disk          = aws_iam_policy.disk.arn
  }
  role       = aws_iam_role.skysql_orchestration.name
  policy_arn = each.value
}
