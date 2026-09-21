# Records the deployment metadata as tags on the account resource group.
# Created after every other resource, so the tags are only present on a
# complete deployment.

resource "azurerm_resource_group_template_deployment" "byoa_metadata" {
  name                = "skysql-byoa-metadata"
  resource_group_name = azurerm_resource_group.account.name

  # Incremental: add these tags, leave the rest of the resource group alone.
  deployment_mode = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    resources = [{
      type       = "Microsoft.Resources/tags"
      apiVersion = "2021-04-01"
      name       = "default"
      properties = { tags = local.metadata_tags }
    }]
  })

  # Azure rejects tag values over 256 characters.
  lifecycle {
    precondition {
      condition     = alltrue([for v in values(local.metadata_tags) : length(v) <= 256])
      error_message = "A deployment metadata tag value exceeds Azure's 256 character limit."
    }
  }

  # Between them these cover every other resource in this module.
  depends_on = [
    azurerm_role_assignment.mdb-cloud-account-role-assignment,
    azurerm_role_assignment.mdbcloud-core-region,
    azurerm_role_assignment.restricted_assignment_with_role_limits,
  ]
}
