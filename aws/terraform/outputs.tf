output "orchestration_role_arn" {
  description = "ARN of the skysql-orchestration role"
  value       = aws_iam_role.skysql_orchestration.arn
}

output "account_id" {
  description = "AWS Account ID where the role was created"
  value       = data.aws_caller_identity.current.account_id
}

output "metadata_parameter_name" {
  description = "SSM parameter holding BYOA deployment metadata"
  value       = aws_ssm_parameter.byoa_metadata.name
}

output "metadata_region" {
  description = "Region the metadata parameter was written to"
  value       = var.default_region
}
