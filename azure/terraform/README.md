# Azure BYOA Terraform Deployment

This directory contains Terraform configuration for deploying the MariaDB Cloud BYOA (Bring Your Own Account) infrastructure on Azure.

## Overview

This Terraform configuration creates:
- Resource groups for account and regional resources
- Azure AD service principal registration
- Custom Azure RBAC role definitions for MariaDB Cloud operations
- Role assignments with appropriate permissions and conditions

## Prerequisites

1. **Terraform installed** (version 1.0 or later):
   ```bash
   terraform version
   ```

2. **Azure CLI installed and configured**:
   ```bash
   az login
   az account set --subscription <your-subscription-id>
   ```

3. **Required Azure permissions**:
   - Owner or User Access Administrator role at the subscription level
   - Ability to create custom role definitions and role assignments
   - Azure AD permissions to register service principals

4. **Azure Storage Account for Terraform state** (see Backend Setup below)

## Backend Setup for State Persistence

Terraform state should be stored remotely for collaboration and safety. We recommend using Azure Storage.

### Create Backend Storage

Run these commands to create a storage account for Terraform state:

```bash
# Set variables
RESOURCE_GROUP_NAME="terraform-state-rg"
STORAGE_ACCOUNT_NAME="tfstate${RANDOM}"  # Must be globally unique
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create storage account
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob \
  --location $LOCATION

# Create blob container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME

# Get storage account key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --query '[0].value' -o tsv)

echo "Storage Account Name: $STORAGE_ACCOUNT_NAME"
echo "Account Key: $ACCOUNT_KEY"
```

### Configure Backend

Create a `backend.tf` file in this directory:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateXXXXX"  # Replace with your storage account name
    container_name       = "tfstate"
    key                  = "byoa-azure.tfstate"
  }
}
```

Alternatively, you can specify backend configuration during initialization:

```bash
terraform init \
  -backend-config="resource_group_name=terraform-state-rg" \
  -backend-config="storage_account_name=tfstateXXXXX" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=byoa-azure.tfstate"
```

## Variables

The Terraform configuration uses the following variables:

| Variable | Type | Description | Default | Required |
|----------|------|-------------|---------|----------|
| `client_id` | string | The client ID of the MariaDB Cloud tenant | - | Yes |
| `regions` | list(string) | List of Azure regions to deploy resources | `["eastus"]` | No |
| `organization_id` | string | Your organization ID | - | Yes |

### Setting Variables

**Option 1: Create a `terraform.tfvars` file**

```hcl
client_id       = "your-client-id"
organization_id = "your-org-id"
regions         = ["eastus", "westus2"]
```

**Option 2: Use command-line flags**

```bash
terraform apply -var="client_id=your-client-id" -var="organization_id=your-org-id" -var='regions=["eastus","westus2"]'
```

**Option 3: Use environment variables**

```bash
export TF_VAR_client_id="your-client-id"
export TF_VAR_organization_id="your-org-id"
export TF_VAR_regions='["eastus","westus2"]'
```

## Deployment

### Initialize Terraform

```bash
# Initialize Terraform (downloads providers and sets up backend)
terraform init
```

### Plan and Apply

```bash
# Review the execution plan
terraform plan

# Apply the configuration
terraform apply

# Or apply without confirmation prompt
terraform apply -auto-approve
```

### Verify Outputs

After successful deployment, Terraform will output the subscription ID:

```bash
terraform output subscription_id
```

## What Gets Created

### Resource Groups

1. **Account Resource Group**: `sky-{organization_id}`
   - Location: East US
   - Contains account-level resources and managed identities

2. **Regional Resource Groups**: `cl-{organization_id}-azure-{region}`
   - One per region specified in the `regions` variable
   - Contains region-specific orchestration resources

### Azure AD Service Principal

- Registers the external MariaDB Cloud service principal in your tenant
- Client ID is provided via the `client_id` variable

### Custom Role Definitions

1. **mdbcloud-account-role**
   - Scope: Account resource group
   - Permissions: Manage user-assigned managed identities and federated credentials

2. **mdbcloud-delegation-role**
   - Scope: Subscription level
   - Permissions: Manage role assignments with conditions limiting which roles can be assigned

3. **mdbcloud-mc-role**
   - Scope: Subscription level (assignable to managed cluster resource groups)
   - Permissions: Manage public IP addresses and load balancers in managed cluster RGs

4. **mdbcloud-core-region-{region}**
   - Scope: Regional resource group (one per region)
   - Permissions: Full orchestration capabilities including:
     - Network management (VNets, subnets, NAT gateways)
     - AKS cluster management
     - Managed identity operations

## Validation

After deployment, verify the resources:

```bash
# Show all Terraform-managed resources
terraform state list

# Show details of a specific resource
terraform state show azurerm_resource_group.account

# Verify with Azure CLI
az group list --query "[?starts_with(name, 'sky-') || starts_with(name, 'cl-')].{Name:name, Location:location}"

# List custom role definitions
az role definition list --custom-role-only true --query "[?starts_with(roleName, 'mdbcloud')].{Name:roleName, Type:roleType}"

# List role assignments
SERVICE_PRINCIPAL_ID=$(terraform state show azuread_service_principal.external_sp | grep object_id | awk '{print $3}' | tr -d '"')
az role assignment list --assignee $SERVICE_PRINCIPAL_ID --all
```

## State Management

### View Current State

```bash
# List all resources in state
terraform state list

# Show state for a specific resource
terraform state show azurerm_resource_group.account
```

### Import Existing Resources

If resources already exist, you can import them:

```bash
terraform import azurerm_resource_group.account /subscriptions/{subscription-id}/resourceGroups/sky-{org-id}
```

### Refresh State

```bash
# Refresh state from actual infrastructure
terraform refresh
```

## Updating the Infrastructure

To modify the infrastructure:

1. Update the Terraform configuration files
2. Run `terraform plan` to review changes
3. Run `terraform apply` to apply changes

### Adding More Regions

Edit your `terraform.tfvars`:

```hcl
regions = ["eastus", "westus2", "centralus"]
```

Then apply:

```bash
terraform apply
```

## Troubleshooting

### Common Issues

1. **"Error creating Service Principal"**
   - Ensure you have Azure AD permissions
   - The service principal may already exist in your tenant
   - Try running: `az ad sp show --id <your-client-id>`

2. **"Backend initialization failed"**
   - Verify storage account exists and you have access
   - Check storage account name and resource group are correct
   - Ensure the container exists

3. **"Insufficient privileges to complete the operation"**
   - Verify you have Owner or User Access Administrator role
   - Check Azure CLI is authenticated: `az account show`

4. **"Role definition already exists"**
   - Import the existing role into Terraform state, or
   - Delete the role and recreate: `az role definition delete --name mdbcloud-account-role`

5. **State file locked**
   - Another process may be running Terraform
   - Force unlock (use with caution): `terraform force-unlock <lock-id>`

### Enable Debug Logging

```bash
export TF_LOG=DEBUG
terraform apply
```

## Destroying Resources

To remove all resources created by Terraform:

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Destroy specific resources
terraform destroy -target=azurerm_resource_group.account
```

**Warning**: This will delete all resources managed by this Terraform configuration. Use with caution in production environments.

## Support

For issues or questions, please refer to the main MariaDB Cloud documentation or contact support.
