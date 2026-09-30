# AWS BYOA CloudFormation Deployment

This directory contains a CloudFormation template for deploying the SkySQL BYOA (Bring Your Own Account) IAM infrastructure on AWS.

## Overview

This CloudFormation template creates:
- An IAM role (`skysql-orchestration`) that the SkySQL orchestration account assumes
- 8 orchestration policies attached to the role (Networking, EKS, Compute, IAM, IAM Deny, Storage, Load Balancing, Disk Volume)
- 7 permission boundary policies that constrain workload roles created by the orchestrator
- 1 SSM parameter recording deployment metadata, written last

**Total resources: 17** (1 IAM role + 8 orchestration policies + 7 permission boundary policies + 1 SSM parameter)

This is functionally equivalent to the Terraform stack in `../terraform/`.

## Prerequisites

1. **AWS CLI installed and configured**:
   ```bash
   aws configure
   ```

2. **Sufficient IAM permissions** in the target account:
   - Ability to create IAM roles, policies, and managed policies
   - Typically requires `AdministratorAccess` or an IAM-capable role

3. **SkySQL orchestration account ID** — the 12-digit AWS Account ID that will assume the orchestration role (provided during BYOA onboarding)

4. **SkySQL organization id** — copy it verbatim from the SkySQL portal

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `OrchestrationAccountId` | String | 12-digit AWS Account ID of the SkySQL orchestration account |
| `OrgId` | String | SkySQL organization id for this account. Copy it verbatim from the SkySQL portal. |

## Deployment

### Validate the template

```bash
aws cloudformation validate-template \
  --template-body file://skysql-byoa.yaml
```

### Deploy the stack

```bash
aws cloudformation deploy \
  --template-file skysql-byoa.yaml \
  --stack-name skysql-byoa \
  --parameter-overrides OrchestrationAccountId=<ACCOUNT_ID> OrgId=<ORG_ID> \
  --capabilities CAPABILITY_NAMED_IAM
```

Replace `<ACCOUNT_ID>` with the 12-digit SkySQL orchestration account ID and
`<ORG_ID>` with your SkySQL organization id.

> **Note:** `--capabilities CAPABILITY_NAMED_IAM` is required because the template creates IAM resources with custom names.

### Update an existing stack

Run the same `deploy` command — CloudFormation will create a change set and apply only the differences.

### Delete the stack

```bash
aws cloudformation delete-stack --stack-name skysql-byoa
```

## What Gets Created

### IAM Role

| Resource | Name |
|----------|------|
| Orchestration Role | `skysql-orchestration` |

The role trusts the specified orchestration account (`sts:AssumeRole` from `arn:aws:iam::<OrchestrationAccountId>:root`).

### Orchestration Policies (attached to role)

| Policy Name | Purpose |
|-------------|---------|
| `SkySQL-Networking-Policy` | VPC, subnets, gateways, routes, security groups, EIPs |
| `SkySQL-EKS-Policy` | EKS cluster provisioning and access entries |
| `SkySQL-Compute-Policy` | EC2 instances, launch templates, autoscaling |
| `SkySQL-IAM-Policy` | IAM role/policy management with boundary enforcement |
| `SkySQL-IAM-Deny-Policy` | Deny statements preventing escalation |
| `SkySQL-Storage-Policy` | S3, DynamoDB for state management |
| `SkySQL-LoadBalancer-Policy` | ELB/ALB/NLB describe operations |
| `SkySQL-DiskVolume-Policy` | EBS volume operations |

### Permission Boundary Policies

| Policy Name | Constrains |
|-------------|------------|
| `SkySQL-ClusterRole-PermissionBoundary` | EKS cluster control plane role |
| `SkySQL-NodeRole-PermissionBoundary` | EKS node pool roles |
| `SkySQL-Autoscaler-PermissionBoundary` | Cluster autoscaler role |
| `SkySQL-LBController-PermissionBoundary` | AWS Load Balancer Controller role |
| `SkySQL-ControllerManager-PermissionBoundary` | skysql-controller-manager role |
| `SkySQL-GarCredential-PermissionBoundary` | gar-credential-controller role |
| `SkySQL-Backup-PermissionBoundary` | skysql backup admin role |

## Verification

After deployment, verify the resources:

```bash
# Check stack status
aws cloudformation describe-stacks --stack-name skysql-byoa \
  --query 'Stacks[0].{Status:StackStatus,Outputs:Outputs}'

# Verify the role exists
aws iam get-role --role-name skysql-orchestration

# List attached policies
aws iam list-attached-role-policies --role-name skysql-orchestration

# List all permission boundary policies
aws iam list-policies --query 'Policies[?starts_with(PolicyName, `SkySQL-`) && contains(PolicyName, `PermissionBoundary`)]'
```
