# MariaDB Cloud BYOC / BYOA onboarding

Templates that grant MariaDB Cloud the permissions it needs to run databases
in your own cloud account.

Pick your cloud:

## Google Cloud

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/open?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fmariadb-corporation%2Fmariadb-byoc-onboarding&cloudshell_git_branch=main&cloudshell_workspace=gcp&cloudshell_tutorial=tutorial.md&show=ide%2Cterminal)

A guided Cloud Shell walkthrough that walks you through checking Terraform,
collecting your MariaDB Cloud details, setting up a state bucket and
applying the configuration — no Terraform knowledge needed. Reference
documentation is in [gcp/README.md](gcp/README.md); the Terraform module
itself is in [gcp/terraform/](gcp/terraform/).

## Azure

- [azure/arm/](azure/arm/) — an ARM template, deployable from the Azure portal,
  the Azure CLI or PowerShell
- [azure/terraform/](azure/terraform/) — the equivalent Terraform module

## Support

Contact MariaDB support, including the summary your cloud's verification step
prints.
