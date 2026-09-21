terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.25.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.6.0"
    }
  }
}

provider "azurerm" {
  features {
    # Leave the tags written by metadata.tf in place; the resource group they
    # are on is deleted anyway.
    template_deployment {
      delete_nested_items_during_deletion = false
    }
  }
  resource_provider_registrations = "none"
  resource_providers_to_register = [
    "Microsoft.Network",
    "Microsoft.ContainerService",
    "Microsoft.Compute",
    "Microsoft.ManagedIdentity",
  ]
}

provider "azuread" {}
