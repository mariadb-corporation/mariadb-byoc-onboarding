# MariaDB Cloud BYOC on Google Cloud

This directory contains everything needed to grant MariaDB Cloud
permission to run databases in your own Google Cloud project — "bring your own
cloud" — plus a guided Cloud Shell walkthrough that walks you through it step
by step.

## Guided setup in Cloud Shell

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/open?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fmariadb-corporation%2Fmariadb-byoc-onboarding&cloudshell_git_branch=main&cloudshell_workspace=gcp&cloudshell_tutorial=tutorial.md&show=ide%2Cterminal)

This is the recommended path, and the only one that does not require any
Terraform knowledge. It opens Google Cloud Shell, clones this repository and
walks through the setup one step at a time:

```
https://shell.cloud.google.com/cloudshell/open?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fmariadb-corporation%2Fmariadb-byoc-onboarding&cloudshell_git_branch=main&cloudshell_workspace=gcp&cloudshell_tutorial=tutorial.md&show=ide%2Cterminal
```

You can also start the walkthrough from a Cloud Shell you already have open:

```bash
git clone https://github.com/mariadb-corporation/mariadb-byoc-onboarding.git
cd mariadb-byoc-onboarding/gcp
cloudshell launch-tutorial tutorial.md
```

The rest of this document is the reference: what gets created, every variable,
and how to run the Terraform by hand.

## Overview

`terraform/` creates, in one project:

- 19 custom IAM roles for MariaDB Cloud operations, most of them scoped by IAM
  conditions to the regions and resource name prefixes MariaDB Cloud uses
- 24 project-level IAM bindings granting those roles to three MariaDB Cloud
  service accounts
- One binding letting the orchestration service account act as the project's
  default Compute Engine service account
- A `skysql-cluster-logs` log view on the `_Default` log bucket
- Seven enabled Google Cloud APIs
- A `skysql-byoc-metadata` project metadata entry, which is how MariaDB Cloud
  recognises the account and, on re-runs, locates the Terraform state

53 resources in total. No databases, networks, subnets or virtual machines are
created here; MariaDB Cloud creates those when you launch a database.

## Prerequisites

1. **Terraform** `>= 1.5, < 2.0`. Check yours:

   ```bash
   terraform version
   ```

   Upgrade via [developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install)
   if needed. Cloud Shell already includes a compatible version.

2. **gcloud, signed in, with application default credentials.** Terraform does
   not use the `gcloud` sign-in directly:

   ```bash
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project PROJECT_ID
   ```

3. **Permissions on the project.** `roles/owner` is the simplest. Otherwise:

   | Role | Needed for |
   | --- | --- |
   | `roles/iam.roleAdmin` | creating the custom roles |
   | `roles/resourcemanager.projectIamAdmin` | granting them |
   | `roles/compute.admin` | the project metadata entry |
   | `roles/iam.serviceAccountAdmin` | the default Compute SA binding |
   | `roles/logging.admin` | the log view |
   | `roles/serviceusage.serviceUsageAdmin` | enabling APIs |
   | `roles/storage.admin` | the Terraform state bucket |

   If you're missing one, Terraform will fail during `apply` with
   `Permission denied` naming exactly which permission is missing.

4. **The four values from the MariaDB Cloud portal**: your organization ID and
   the three service account addresses.

5. **A Cloud Storage bucket for Terraform state** — optional but strongly
   recommended, see below.

## Backend setup for state persistence

Terraform records what it created in a *state* file, and needs it again to
update, extend or remove the deployment. Store it in Cloud Storage.

```bash
PROJECT_ID="my-project"
BUCKET="${PROJECT_ID}-skysql-byoc-tfstate"
LOCATION="us-central1"

gcloud storage buckets create "gs://${BUCKET}" \
  --project="${PROJECT_ID}" \
  --location="${LOCATION}" \
  --uniform-bucket-level-access \
  --public-access-prevention

gcloud storage buckets update "gs://${BUCKET}" --versioning
```

Then create `terraform/backend.tf`:

```hcl
terraform {
  backend "gcs" {
    bucket = "my-project-skysql-byoc-tfstate"
    prefix = "skysql-byoc/my-project"
  }
}
```

or pass the same values at init time:

```bash
terraform init \
  -backend-config="bucket=my-project-skysql-byoc-tfstate" \
  -backend-config="prefix=skysql-byoc/my-project"
```

There is no backend committed to this repository, so a plain `terraform init`
keeps state in `terraform/terraform.tfstate` on the local disk. That works, but
if you lose that file Terraform can no longer manage the deployment: a fresh
run fails against the 43 roles and bindings that already exist, and each has to
be imported by hand (see Troubleshooting).

## Variables

| Variable | Type | Description | Default | Required |
| --- | --- | --- | --- | --- |
| `project_id` | string | GCP project to deploy into | - | Yes |
| `org_id` | string | Your **MariaDB Cloud** organization ID (not a Google Cloud org ID) | - | Yes |
| `allowed_regions` | list(string) | Regions MariaDB Cloud may create resources in; the first is also the provider's default region | - | Yes |
| `orchestration_project_id` | string | GCP project hosting MariaDB Cloud's standard service accounts; derives the three accounts below when set. | - | Yes |
| `orchestration_sa_email` | string | MariaDB Cloud orchestration service account; overrides the derived value | `null` | See below |
| `federated_manager_sa_email` | string | MariaDB Cloud federated manager service account; overrides the derived value | `null` | See below |
| `backup_sa_email` | string | MariaDB Cloud backup service account; overrides the derived value | `null` | See below |
| `state_bucket` | string | Bucket holding this deployment's Terraform state; empty means local state | `""` | No |
| `state_prefix` | string | Object prefix within `state_bucket` | `""` | No |

Set either `orchestration_project_id`, or all three of
`orchestration_sa_email`/`federated_manager_sa_email`/`backup_sa_email` — an
explicit email always overrides the value derived from
`orchestration_project_id` for that one account. `orchestration_project_id`
has no default, so Terraform always asks for it; enter `""` (empty) at that
prompt if you're setting the three emails individually instead.

### Setting variables

**Option 1: a `terraform.tfvars` file** — copy
`terraform/terraform.tfvars.example` and fill it in.

**Option 2: command-line flags**

```bash
terraform apply \
  -var="project_id=my-project" \
  -var="org_id=my-skysql-org-id" \
  -var='allowed_regions=["us-central1","us-east1"]'
```

**Option 3: environment variables**

```bash
export TF_VAR_project_id="my-project"
export TF_VAR_org_id="my-skysql-org-id"
export TF_VAR_allowed_regions='["us-central1","us-east1"]'
```

## Deployment

```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

If `backend.tf` changes after a previous `init`, Terraform will prompt you to
migrate existing state into the new location or reconfigure and start fresh
there. Read the `plan` before applying it — if
`google_compute_project_metadata_item.byoc_metadata`'s `stack_id` would go
from a value to `null` and you didn't intend to move to local state, stop and
check your `backend.tf`/`terraform.tfvars` first.

### Verify outputs

```bash
terraform output                 # everything
terraform output state_location  # gs://BUCKET/PREFIX, or null for local state
terraform output byoc_metadata   # what was written to project metadata
```

## What gets created

### Custom roles (19)

`SkySQLStoragee`, `SkySQLStorageLister`, `SkySQLStorageCreator`,
`SkySQLWorkloadIdentityCreator`, `SkySQLSACreator`, `SkySQLContainerCreator`,
`SkySQLContainerAdmin`, `SkySQLControllerManager`, `SkySQLNetworkAdmin`,
`SkySQLNetworkCleanup`, `SkySQLIAMAdmin`, `SkySQLIAMProjectAdmin`,
`SkySQLDefaultNetworkUpdater`, `SkySQLDefaultSubnetworkUser`,
`SkySQLFirewallManager`, `SkySQLAddressLabeler`, `SkySQLDBSubnetworkManager`,
`SkySQLBackupPod`, `SkySQLMonitoringViewer`.

`SkySQLControllerManager` and `SkySQLBackupPod` are created but deliberately
not bound to anything: MariaDB Cloud grants them to workload identities inside
your clusters at run time.

Most bindings carry IAM conditions restricting them to the regions in
`allowed_regions` and to resource names prefixed `cl-org`, `db` or `skysql`.

### IAM bindings (24, plus one service account binding)

Granted to the three service accounts you supplied. The orchestration account
also receives `roles/iam.serviceAccountUser` on the project's default Compute
Engine service account.

### Other

- `google_logging_log_view.cluster_logs` — `skysql-cluster-logs`, filtered to
  clusters named `cl-org*`
- `google_project_service` — `serviceusage`, `cloudresourcemanager`, `compute`,
  `container`, `file`, `iam` and `logging`, with `disable_on_destroy = false`
- `google_compute_project_metadata_item.byoc_metadata` — the
  `skysql-byoc-metadata` key, a JSON object:

  ```json
  {
    "template_version": "1.0.0",
    "deployment_method": "terraform",
    "org_id": "YOUR_SKYSQL_ORG_ID",
    "orchestration_account_id": "orchestration SA email",
    "orchestration_role_arn": "orchestration SA email",
    "account_id": "PROJECT_ID",
    "region": "us-central1,us-east1",
    "stack_id": "gs://BUCKET/PREFIX"
  }
  ```

  `stack_id` is the Terraform state location, or `null` when state is local.
  This is the same key set as the Azure deployment uses.


## Updating the deployment

### Adding a region

Edit `allowed_regions` in `terraform/terraform.tfvars`, then:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

Adding a region changes the IAM conditions on the region-scoped bindings and
the `region` value in the metadata. Existing databases are unaffected.

### Updating the template

Pull the latest version of this repository and run `plan` and `apply` again.
`template_version` in the metadata tells MariaDB Cloud which version you are on.

## Troubleshooting

**`Error 403: Permission denied` during apply.** You are missing one of the
roles under Prerequisites — the error message names the specific permission;
match it against the roles table there to see which one to ask for.

**`Role ... already exists` / `Error 409` during apply.** The resources exist
but Terraform has no record of them — usually local state that was lost. Either
delete the leftovers, or import them:

```bash
cd terraform
P="$(gcloud config get-value project)"

terraform import google_compute_project_metadata_item.byoc_metadata \
  "${P}/skysql-byoc-metadata"

terraform import 'google_project_iam_custom_role.skysql_storage' \
  "projects/${P}/roles/SkySQLStoragee"
# ... once per role in terraform/iam.tf, using its role_id

# Conditional bindings need the condition title as a fourth field:
terraform import 'google_project_iam_member.skysql_storage' \
  "${P} projects/${P}/roles/SkySQLStoragee serviceAccount:ORCH_SA restrict_to_skysql_buckets"
```

Run `terraform plan` after each batch; it will tell you what is still missing.
This is tedious, which is the reason to keep state in a bucket.

**`Backend configuration changed`.** Run `terraform init` again; it will
prompt you to migrate existing state into the new location or reconfigure
and start fresh there.

**`Error acquiring the state lock`.** Someone else is running Terraform against
the same state, or a previous run was killed. If you are certain nobody else is
running it, `terraform force-unlock LOCK_ID`.

**Terraform cannot authenticate.** Run `gcloud auth application-default login`.
If that is not possible in your environment:

```bash
export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)"
```

That token expires after about an hour and Terraform cannot refresh it.

**Cloud Shell has no credentials.** Cloud Shell sessions opened from a
repository that Google has not allowlisted can start in a temporary environment
without your credentials, and without a persistent home directory. Signing in
as above fixes the credentials; for the home directory, keep your state in a
bucket so nothing is lost when the session ends.

**Verbose logs.** `export TF_LOG=DEBUG` before running Terraform.

## Destroying

Only do this once no MariaDB Cloud databases remain in the project. Destroying
removes the `skysql-byoc-metadata` entry that MariaDB Cloud reads to find your account,
and the roles its service accounts rely on.

```bash
cd terraform
terraform destroy
```

Terraform will show the full destroy plan and ask you to type `yes` before
it removes anything.

Enabled APIs are left enabled (`disable_on_destroy = false`), and the Terraform
state bucket is not managed by Terraform. Delete it yourself when you are
finished — `terraform output state_location` names it:

```bash
gcloud storage rm -r "gs://BUCKET"
```

## Support

Contact MariaDB support with your project ID, `terraform output byoc_metadata`,
and the `skysql-byoc-metadata` value from `gcloud compute project-info describe`.
