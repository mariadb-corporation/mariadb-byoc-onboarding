# Azure BYOA ARM Template Deployment

This directory contains ARM (Azure Resource Manager) templates for deploying the MariaDB Cloud BYOA (Bring Your Own Account) infrastructure on Azure.

## Overview

This ARM template creates:
- Resource groups for account and regional resources
- Custom Azure RBAC role definitions for MariaDB Cloud operations
- Role assignments with appropriate permissions and conditions

## Prerequisites

MariaDB Cloud requires an Azure AD service principal to manage resources in your Azure subscription.
The ID for the MariaDB Cloud application will be provided for you during the BYOA onbroading process.
Before deploying this ARM template, you must:

1. **Create an Azure AD Service Principal** for the MariaDB Cloud application:
   ```bash
   # Create the service principal
   az ad sp create --id <service_principal_id>

   # Get the Object ID (you'll need this for the deployment)
   az ad sp show --id <service_principal_id> --query id -o tsv
   ```

2. **Ensure you have the necessary permissions** in your Azure subscription:
   - Owner or User Access Administrator role at the subscription level
   - Ability to create custom role definitions and role assignments

3. **Azure CLI installed and configured**:
   ```bash
   az login
   az account set --subscription <your-subscription-id>
   ```

## Parameters

The template requires the following parameters:

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `clientId` | string | The client ID of the MariaDB Cloud tenant | *Required* |
| `regions` | array | List of Azure regions to deploy resources | `["eastus"]` |
| `organizationId` | string | Your organization ID | *Required* |
| `servicePrincipalObjectId` | string | Object ID of the Azure AD service principal | *Required* |

## Deployment

### Option 1: Using Azure CLI

1. **Edit the parameters file** (`azuredeploy.parameters.json`):
   - Replace `YOUR_ORGANIZATION_ID` with your actual organization ID
   - Replace `YOUR_SERVICE_PRINCIPAL_OBJECT_ID` with the Object ID from the prerequisites step
   - Modify `regions` array if you need multiple regions

2. **Deploy the template**:
   ```bash
   az deployment sub create \
     --location eastus \
     --template-file azuredeploy.json \
     --parameters azuredeploy.parameters.json
   ```

### Option 2: Using Azure Portal

1. Navigate to the Azure Portal
2. Search for "Deploy a custom template"
3. Select "Build your own template in the editor"
4. Copy and paste the contents of `azuredeploy.json`
5. Fill in the required parameters
6. Review and create

### Option 3: Using PowerShell

```powershell
New-AzSubscriptionDeployment `
  -Location "eastus" `
  -TemplateFile "azuredeploy.json" `
  -TemplateParameterFile "azuredeploy.parameters.json"
```

## What Gets Created

### Resource Groups

1. **Account Resource Group**: `sky-{organizationId}`
   - Location: East US
   - Contains account-level resources and managed identities

2. **Regional Resource Groups**: `cl-{organizationId}-azure-{region}`
   - One per region specified in the `regions` parameter
   - Contains region-specific orchestration resources

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
   - Scope: Regional resource group
   - Permissions: Full orchestration capabilities including:
     - Network management (VNets, subnets, NAT gateways)
     - AKS cluster management
     - Managed identity operations

## Validation

After deployment, verify the resources were created:

```bash
# List resource groups
az group list --query "[?starts_with(name, 'sky-') || starts_with(name, 'cl-')].{Name:name, Location:location}"

# List custom role definitions
az role definition list --custom-role-only true --query "[?starts_with(roleName, 'mdbcloud')].{Name:roleName, Scope:assignableScopes[0]}"

# List role assignments for your service principal
az role assignment list --assignee YOUR_SERVICE_PRINCIPAL_OBJECT_ID --all
```

## Troubleshooting

### Common Issues

1. **"The client does not have authorization to perform action"**
   - Ensure you have Owner or User Access Administrator role at the subscription level

2. **"Service principal not found"**
   - Make sure you've created the service principal using the prerequisites step
   - Verify the Object ID is correct

3. **"Role definition already exists"**
   - Custom role names must be unique within the subscription
   - Either delete the existing role or modify the role names in the template

4. **Deployment times out**
   - Large deployments with many regions may take 10-15 minutes
   - Check the deployment status in the Azure Portal

## Support

For issues or questions, please refer to the main MariaDB Cloud documentation or contact support.
