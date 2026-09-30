# AWS BYOA Terraform Deployment

This root module creates the SkySQL BYOA (Bring Your Own Account) IAM
infrastructure on AWS. It is functionally equivalent to the CloudFormation
template in `../cloudformation/`, and the two are kept in sync by hand — a
cross-template test in `moe/tests/byoa_tests/test_byoa_metadata.py` pins the
metadata they write.

```bash
terraform init
terraform apply -var orchestration_account_id=<ACCOUNT_ID> -var org_id=<ORG_ID>
```

## Deployment Metadata

Once every other resource has been created successfully, the module writes an
SSM parameter, `/skysql/byoa/metadata`:

```json
{
  "template_version": "1.0.0",
  "deployment_method": "terraform",
  "org_id": "<ORG_ID>",
  "orchestration_account_id": "<ACCOUNT_ID>",
  "account_id": "<THIS_ACCOUNT>",
  "region": "<DEFAULT_REGION>",
  "orchestration_role_arn": "arn:aws:iam::<THIS_ACCOUNT>:role/skysql-orchestration"
}
```

<!--
The reference tables below are in terraform-docs format, but nothing
regenerates them: .github/workflows/terraform.yaml only scans
moe/moe/assets/terraform/. Update them by hand when adding or removing
resources, variables or outputs.
-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.59 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.59 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.autoscaler_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.backup_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.cluster_role_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.compute](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.controller_manager_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.disk](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.gar_credential_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.iam](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.lb_controller_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.loadbalancing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.networking](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.node_role_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.skysql_orchestration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.skysql_orchestration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_ssm_parameter.byoa_metadata](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.autoscaler_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.backup_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cluster_role_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.compute](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.controller_manager_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.controller_manager_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.controller_manager_restrictions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.gar_credential_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.iam](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lb_controller_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.loadbalancing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.networking](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.node_role_permission_boundary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_region"></a> [default\_region](#input\_default\_region) | AWS region for resource deployment | `string` | `"us-east-2"` | no |
| <a name="input_orchestration_account_id"></a> [orchestration\_account\_id](#input\_orchestration\_account\_id) | AWS Account ID of the SkySQL orchestration account that will assume the skysql-orchestration role | `string` | n/a | yes |
| <a name="input_org_id"></a> [org\_id](#input\_org\_id) | SkySQL organization id for this account. Copy it verbatim from the SkySQL portal. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | AWS Account ID where the role was created |
| <a name="output_metadata_parameter_name"></a> [metadata\_parameter\_name](#output\_metadata\_parameter\_name) | SSM parameter holding BYOA deployment metadata |
| <a name="output_metadata_region"></a> [metadata\_region](#output\_metadata\_region) | Region the metadata parameter was written to |
| <a name="output_orchestration_role_arn"></a> [orchestration\_role\_arn](#output\_orchestration\_role\_arn) | ARN of the skysql-orchestration role |
<!-- END_TF_DOCS -->
