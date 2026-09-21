data "azurerm_client_config" "current" {}

data "azurerm_role_definition" "allowed_roles" {
  for_each = toset(local.allowed_role_definition_names)
  name     = each.value
}

resource "azurerm_resource_group" "account" {
  name     = "sky-${var.organization_id}"
  location = "eastus"

  # Tags are set by metadata.tf, not here.
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_resource_group" "region" {
  for_each = toset(var.regions)
  name     = "cl-${var.organization_id}-azure-${local.region_label[each.value]}"
  location = each.value
}

resource "azuread_service_principal" "external_sp" {
  client_id   = var.client_id
  description = "MariaDB Cloud Service Principal for Orcheestration and Provisioning."
}

resource "azurerm_role_definition" "mdb-cloud-account-role" {
  name        = "mdbcloud-${var.organization_id}-account-role"
  scope       = azurerm_resource_group.account.id
  description = "Manage things inside the account RG"

  permissions {
    actions = [
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
      "Microsoft.ManagedIdentity/userAssignedIdentities/delete",
      "Microsoft.ManagedIdentity/userAssignedIdentities/listAssociatedResources/action",
      "Microsoft.ManagedIdentity/userAssignedIdentities/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/write",
      "Microsoft.ManagedIdentity/userAssignedIdentities/revokeTokens/action",
      "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/write",
      "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/delete"
    ]
    not_actions  = []
    data_actions = []
  }
}

resource "azurerm_role_assignment" "mdb-cloud-account-role-assignment" {
  scope                = azurerm_resource_group.account.id
  role_definition_name = azurerm_role_definition.mdb-cloud-account-role.name
  principal_id         = azuread_service_principal.external_sp.object_id
  description          = "Manage resources inside the account RG"
}

resource "azurerm_role_definition" "mdbcloud-delegation-role" {
  name        = "mdbcloud-${var.organization_id}-delegation-role"
  scope       = "/subscriptions/${local.subscription_id}"
  description = "Manage permissions inside the managed cluster RG"

  permissions {
    actions = [
      "Microsoft.Authorization/roleAssignments/read",
      "Microsoft.Authorization/roleAssignments/write",
      "Microsoft.Authorization/roleAssignments/delete",
      "Microsoft.Resources/subscriptions/resourcegroups/read",
    ]
    not_actions  = []
    data_actions = []
  }

  assignable_scopes = [
    "/subscriptions/${local.subscription_id}",
  ]
}

resource "azurerm_role_definition" "mdbcloud-mc-role" {
  name        = "mdbcloud-${var.organization_id}-mc-role"
  scope       = "/subscriptions/${local.subscription_id}"
  description = "Manage things inside the managed cluster RG"

  permissions {
    actions = [
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/publicIPAddresses/delete",
      "Microsoft.Network/loadBalancers/read",
      "Microsoft.Network/loadBalancers/write",
      "Microsoft.Network/loadBalancers/delete",
      "Microsoft.Network/privateLinkServices/read",
      "Microsoft.Network/privateLinkServices/write",
      "Microsoft.Network/privateLinkServices/delete",
      "Microsoft.Network/privateLinkServices/PrivateEndpointConnectionsApproval/action",
      "Microsoft.Network/privateLinkServices/privateEndpointConnections/read",
      "Microsoft.Network/privateLinkServices/privateEndpointConnections/write",
      "Microsoft.Network/privateLinkServices/privateEndpointConnections/delete",
    ]
    not_actions  = []
    data_actions = []
  }

  assignable_scopes = concat(
    ["/subscriptions/${local.subscription_id}"],
    local.mc_scopes
  )
}


resource "azurerm_role_definition" "mdbcloud-core-region" {
  for_each    = toset(var.regions)
  name        = "mdbcloud-${var.organization_id}-core-region-${each.value}"
  scope       = azurerm_resource_group.region[each.value].id
  description = "Manage core orchestration in a region"

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resourceGroups/write",
      "Microsoft.Resources/subscriptions/resourceGroups/delete",
      "Microsoft.Resources/subscriptions/resourceGroups/moveResources/action",
      "Microsoft.Resources/subscriptions/resourceGroups/validateMoveResources/action",
      "Microsoft.Network/internalPublicIpAddresses/read",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/publicIPAddresses/delete",
      "Microsoft.Network/publicIPAddresses/join/action",
      "Microsoft.Network/natGateways/read",
      "Microsoft.Network/natGateways/write",
      "Microsoft.Network/natGateways/delete",
      "Microsoft.Network/natGateways/join/action",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/write",
      "Microsoft.Network/virtualNetworks/delete",
      "Microsoft.Network/virtualNetworks/joinLoadBalancer/action",
      "Microsoft.Network/virtualNetworks/join/action",
      "Microsoft.Network/virtualNetworks/listDnsResolvers/action",
      "Microsoft.Network/virtualNetworks/listDnsForwardingRulesets/action",
      "Microsoft.Network/virtualNetworks/checkIpAddressAvailability/read",
      "Microsoft.Network/virtualNetworks/privateDnsZoneLinks/read",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/virtualNetworks/subnets/write",
      "Microsoft.Network/virtualNetworks/subnets/delete",
      "Microsoft.Network/virtualNetworks/subnets/joinLoadBalancer/action",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/joinViaServiceEndpoint/action",
      "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/virtualMachines/read",
      "Microsoft.Network/virtualNetworks/subnets/virtualMachines/read",
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.ContainerService/managedClusters/write",
      "Microsoft.ContainerService/managedClusters/delete",
      "Microsoft.ContainerService/managedClusters/start/action",
      "Microsoft.ContainerService/managedClusters/stop/action",
      "Microsoft.ContainerService/managedClusters/abort/action",
      "Microsoft.ContainerService/managedClusters/listClusterAdminCredential/action",
      "Microsoft.ContainerService/managedClusters/listClusterUserCredential/action",
      "Microsoft.ContainerService/managedClusters/listClusterMonitoringUserCredential/action",
      "Microsoft.ContainerService/managedClusters/resetServicePrincipalProfile/action",
      "Microsoft.ContainerService/managedClusters/unpinManagedCluster/action",
      "Microsoft.ContainerService/managedClusters/resolvePrivateLinkServiceId/action",
      "Microsoft.ContainerService/managedClusters/resetAADProfile/action",
      "Microsoft.ContainerService/managedClusters/rotateClusterCertificates/action",
      "Microsoft.ContainerService/managedClusters/runCommand/action",
      "Microsoft.ContainerService/managedClusters/privateEndpointConnectionsApproval/action",
      "Microsoft.ContainerService/managedClusters/agentPools/upgradeNodeImageVersion/write",
      "Microsoft.ContainerService/managedClusters/agentPools/read",
      "Microsoft.ContainerService/managedClusters/agentPools/write",
      "Microsoft.ContainerService/managedClusters/agentPools/delete",
      "Microsoft.ContainerService/managedClusters/agentPools/upgradeNodeImageVersion/action",
      "Microsoft.ContainerService/managedClusters/agentPools/abort/action",
      "Microsoft.ContainerService/managedClusters/agentPools/upgradeProfiles/read",
      "Microsoft.ContainerService/managedClusters/diagnosticsState/read",
      "Microsoft.ContainerService/managedClusters/extensionaddons/read",
      "Microsoft.ContainerService/managedClusters/extensionaddons/write",
      "Microsoft.ContainerService/managedClusters/extensionaddons/delete",
      "Microsoft.ContainerService/managedClusters/maintenanceConfigurations/read",
      "Microsoft.ContainerService/managedClusters/maintenanceConfigurations/write",
      "Microsoft.ContainerService/managedClusters/maintenanceConfigurations/delete",
      "Microsoft.ContainerService/managedClusters/detectors/read",
      "Microsoft.ContainerService/managedClusters/accessProfiles/read",
      "Microsoft.ContainerService/managedClusters/accessProfiles/listCredential/action",
      "Microsoft.ContainerService/managedClusters/availableAgentPoolVersions/read",
      "Microsoft.ContainerService/managedClusters/commandResults/read",
      "Microsoft.ContainerService/managedClusters/meshUpgradeProfiles/read",
      "Microsoft.ContainerService/managedClusters/providers/Microsoft.Insights/diagnosticSettings/read",
      "Microsoft.ContainerService/managedClusters/providers/Microsoft.Insights/diagnosticSettings/write",
      "Microsoft.ContainerService/managedClusters/trustedAccessRoleBindings/read",
      "Microsoft.ContainerService/managedClusters/trustedAccessRoleBindings/write",
      "Microsoft.ContainerService/managedClusters/trustedAccessRoleBindings/delete",
      "Microsoft.ContainerService/managedClusters/privateEndpointConnections/read",
      "Microsoft.ContainerService/managedClusters/privateEndpointConnections/write",
      "Microsoft.ContainerService/managedClusters/privateEndpointConnections/delete",
      "Microsoft.ContainerService/managedClusters/providers/Microsoft.Insights/logDefinitions/read",
      "Microsoft.ContainerService/managedClusters/providers/Microsoft.Insights/metricDefinitions/read",
      "Microsoft.ContainerService/managedClusters/upgradeProfiles/read",
      "Microsoft.ContainerService/managedclustersnapshots/read",
      "Microsoft.ContainerService/managedclustersnapshots/write",
      "Microsoft.ContainerService/managedclustersnapshots/delete",
      "Microsoft.ManagedIdentity/register/action",
      "Microsoft.ManagedIdentity/operations/read",
      "Microsoft.ManagedIdentity/identities/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/assign/action",
      "Microsoft.ManagedIdentity/userAssignedIdentities/delete",
      "Microsoft.ManagedIdentity/userAssignedIdentities/listAssociatedResources/action",
      "Microsoft.ManagedIdentity/userAssignedIdentities/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/write",
      "Microsoft.ManagedIdentity/userAssignedIdentities/revokeTokens/action",
      "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/read",
      "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/write",
      "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/delete"
    ]
    data_actions = [
      "Microsoft.ContainerService/managedClusters/*"
    ]
  }
}

resource "azurerm_role_assignment" "mdbcloud-core-region" {
  for_each             = azurerm_resource_group.region
  scope                = each.value.id
  role_definition_name = azurerm_role_definition.mdbcloud-core-region[each.key].name
  principal_id         = azuread_service_principal.external_sp.object_id
  description          = "Manage core orchestration in a region"
}

resource "azurerm_role_assignment" "restricted_assignment_with_role_limits" {
  scope                = "/subscriptions/${local.subscription_id}"
  role_definition_name = azurerm_role_definition.mdbcloud-delegation-role.name
  principal_id         = azuread_service_principal.external_sp.object_id

  condition_version = "2.0"
  condition         = <<-EOT
  (
    (
      !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
    )
    OR 
    (
      @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${join(", ", formatlist("%s", concat(local.allowed_role_definition_ids, local.custom_role_ids)))}}
    )
  )
  EOT

  description = "testing conditions role"
}
