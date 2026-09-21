# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  allowed_role_definition_names = [
    "Network Contributor",
    "Disk Snapshot Contributor",
  ]
  subscription_id             = data.azurerm_client_config.current.subscription_id
  allowed_role_definition_ids = [for role in data.azurerm_role_definition.allowed_roles : split("/", role.id)[length(split("/", role.id)) - 1]]
  custom_role_ids             = [azurerm_role_definition.mdbcloud-mc-role.role_definition_id]

  # Shorten only the region
  # embedded in the cluster name so Azure's managed RG (MC_<name>_<name>_<region>)
  # stays within its 80 char limit. The trailing _<region> below is Azure's own
  # append and must stay the full region. cl_prefix_len = len("cl-<org>-azure-").
  azure_mrg_max = 80
  cl_prefix_len = 10 + length(var.organization_id)
  region_label = { for r in var.regions : r => (
    length(r) <= floor((local.azure_mrg_max - 5 - 2 * local.cl_prefix_len - length(r)) / 2)
    ? r
    : format(
      "%s%s",
      substr(
        replace(r, "/[0-9]+$/", ""),
        0,
        max(floor((local.azure_mrg_max - 5 - 2 * local.cl_prefix_len - length(r)) / 2) - length(try(regex("[0-9]+$", r), "")), 0)
      ),
      try(regex("[0-9]+$", r), "")
    )
  ) }

  mc_scopes = [for region in var.regions : "/subscriptions/${local.subscription_id}/resourceGroups/MC_cl-${var.organization_id}-azure-${local.region_label[region]}_cl-${var.organization_id}-azure-${local.region_label[region]}_${region}"]

  template_version = "1.0.0"

  # Deployment metadata recorded in the account resource group's tags.
  metadata = {
    template_version         = local.template_version
    deployment_method        = "terraform"
    org_id                   = var.organization_id
    orchestration_account_id = ""
    account_id               = "${data.azurerm_client_config.current.tenant_id}:${local.subscription_id}"
    region                   = azurerm_resource_group.account.location
    orchestration_role_arn   = azuread_service_principal.external_sp.object_id
    stack_id                 = null
  }

  # Truncated to Azure's 256 character tag value limit.
  regions_tag = join(",", var.regions)

  metadata_tags = merge(
    {
      platform       = "skysql"
      skysql_regions = length(local.regions_tag) > 256 ? substr(local.regions_tag, 0, 256) : local.regions_tag
    },
    { for k, v in local.metadata : "skysql_${k}" => v if v != null }
  )
}
