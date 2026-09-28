# Set up MariaDB Cloud BYOC on Google Cloud

<walkthrough-tutorial-duration duration="20"></walkthrough-tutorial-duration>

This walkthrough gives MariaDB Cloud permission to run databases in
**your own** Google Cloud project — "bring your own cloud".

It uses Terraform, but you do not need to know Terraform: each step below
gives you the exact commands to run yourself, and nothing is changed in your
project until you have seen a summary of exactly what will change and
confirmed it.

## What this sets up

**What it creates in your project**

* 19 custom IAM roles, scoped to the regions you choose
* IAM bindings that grant those roles to three MariaDB Cloud service accounts
* A log view so you can read your database cluster logs
* A `skysql-byoc-metadata` entry on the project, which is how MariaDB Cloud
  recognises your account
* Optionally, a Cloud Storage bucket to keep a record of the above

No databases, networks or virtual machines are created here. MariaDB Cloud
creates those later, when you launch a database.

**What you need**

* The **Owner** role on the Google Cloud project you want to use (or the
  narrower set of roles listed in
  <walkthrough-editor-open-file filePath="README.md">README.md</walkthrough-editor-open-file>)
* Values from the MariaDB Cloud portal: your organization ID, and either the
  three service account addresses or, if they share a common project suffix,
  just that project's ID. Keep that browser tab open — you will fill them in
  at step 6.

Click **Start** to begin.

## Choose your project

Pick the Google Cloud project MariaDB Cloud should use. The permissions
granted here apply to the whole project.

<walkthrough-project-setup billing=true></walkthrough-project-setup>

Terraform's state backend needs three Google Cloud APIs enabled
(Terraform enables everything else it needs itself). Check which of them
already are — this only needs read access, not the elevated permission the
next step requires:

```bash
gcloud config set project <walkthrough-project-id/>
gcloud services list --enabled \
  --filter="config.name=(serviceusage.googleapis.com OR cloudresourcemanager.googleapis.com OR storage.googleapis.com)" \
  --format="value(config.name)"
```

If all three (`serviceusage`, `cloudresourcemanager`, `storage`) are listed,
skip ahead — nothing left to do here. Otherwise, click below to enable
whatever's missing (this needs Editor, Owner, or Service Usage Admin on the
project):

<walkthrough-enable-apis apis="serviceusage.googleapis.com,cloudresourcemanager.googleapis.com,storage.googleapis.com"></walkthrough-enable-apis>

<walkthrough-footnote>Your project ID is <walkthrough-project-id/>. Everything below applies to that project only.</walkthrough-footnote>

## Install Terraform

You'll need the **Owner** role on this project (or the narrower set of roles
listed in
<walkthrough-editor-open-file filePath="README.md">README.md</walkthrough-editor-open-file>).
If anything is missing, Terraform will fail later with a `Permission denied`
error naming exactly what's missing.

Check to see if Terraform is installed:

```bash
terraform version
```

If Terraform is not installed, follow the instructions printed by above command
install terraform in your Cloud Shell environment.

## Reuse settings from a previous run (optional)

If you've set this project up before, we can attempt to recover the values
entered in your previous run to simplify the installation process:

```bash
gcloud compute project-info describe --project "$GOOGLE_CLOUD_PROJECT" --format=json \
  | jq -r '.commonInstanceMetadata.items[] | select(.key=="skysql-byoc-metadata") | .value' \
  > metadata.json

cat metadata.json | jq .
```

**Nothing printed?** This is your first run in this project — skip ahead to
**Choose where Terraform keeps its record**.

**Otherwise**, pull the values back out of it:

```bash
export TF_VAR_project_id="$(jq -r '.account_id' metadata.json)"
export TF_VAR_org_id="$(jq -r '.org_id' metadata.json)"
export TF_VAR_allowed_regions="$(jq -c '.region | split(",")' metadata.json)"
export TF_VAR_orchestration_project_id="$(jq -r '.orchestration_account_id' metadata.json)"
export TF_VAR_state_bucket="$(jq -r '.stack_id // ""' metadata.json | cut -d/ -sf3)"
export TF_VAR_state_prefix="$(jq -r '.stack_id // ""' metadata.json | cut -d/ -sf4-)"
```


## Choose where Terraform keeps its record

Terraform writes down what it created, in a file called *state*. It needs
that file again later — to add a region, to update the setup, or to remove
it cleanly. It's recommended to store this in a Cloud Storage bucket.

If **Reuse settings from a previous run** above found one, these values are 
already set — **skip ahead** to confirming the
bucket below. Otherwise, select the bucket and an optional path prefix where
you'd like to store the state, and set it here. Replace <your-bucket-name>
with the name of the GCS bucket you'd like to store the terraform state in.

```bash
export TF_VAR_state_bucket="<your-bucket-name>"
export TF_VAR_state_prefix="mariadb-byoc/"
```

Confirm the bucket exists and you have permissions to read it. On success,
this prints just the bucket's name:

```bash
gcloud storage buckets describe "gs://${TF_VAR_state_bucket}" --format="value(name)"
```

A `404` means the bucket doesn't exist — follow the instructions to create it
in the next step.

### Create a new bucket (optional)

Creates a Cloud Storage bucket in your own project, with object versioning turned on.

```bash
gcloud storage buckets create "gs://${TF_VAR_state_bucket}" \
  --location="us-central-1" \
  --uniform-bucket-level-access \
  --public-access-prevention

gcloud storage buckets update "gs://${TF_VAR_state_bucket}" --versioning
```

## Connect Terraform

This downloads the Google provider and connects Terraform to the state
location you chose.

```bash
cd terraform
cp backend.tf.example backend.tf
terraform init \
  -backend-config="bucket=${TF_VAR_state_bucket}" \
  -backend-config="prefix=${TF_VAR_state_prefix}"
```

If you've run `init` before against a different bucket or prefix, Terraform
will ask whether to migrate the existing state into the new location or
reconfigure and start fresh there — answer based on whether you're moving
real state or starting over.

## Review what will change

Nothing has been changed in your project yet. This step prints the full list
and saves it, so that what you approve is exactly what gets applied.

```bash
terraform plan -out=tfplan
```

Terraform will prompt you for four values, one at a time — have the MariaDB
Cloud portal's BYOC setup page open for the last two:

| It asks for | Where to find it | Looks like |
| --- | --- | --- |
| `project_id` | The project you chose above | `<walkthrough-project-id/>` |
| `allowed_regions` | The GCP region(s) you want to run databases in. The first one is also used as the default region for other resources this creates. | `["us-central1"]` |
| `orchestration_project_id` | MariaDB Cloud portal, BYOC setup page — the shared project suffix of the three service account emails. Leave blank if you set the three emails individually above. | `test-skysql-infra-406507` |
| `org_id` | MariaDB Cloud portal, BYOC setup page (this is your **MariaDB Cloud** org ID, not a Google Cloud one) | `a1b2c3d4-...` |


**What a good first run looks like:** 53 resources to add — 19
`google_project_iam_custom_role`, 24 `google_project_iam_member`, one
`google_service_account_iam_member`, one `google_logging_log_view`, seven
`google_project_service`, and one `google_compute_project_metadata_item`.
Nothing to change or destroy.

**Stop and check** if the plan wants to *destroy*

## Apply it

```bash
terraform apply tfplan
```

This takes two to five minutes. Two failures are common and both are safe to
retry after fixing:

* `Permission denied` / `403` — your account is missing one of the roles listed
  at step 3. Ask for it, then run the command again.
* `Role ... already exists` — a previous run created the roles but its state
  record was lost. See **Troubleshooting** in
  <walkthrough-editor-open-file filePath="README.md">README.md</walkthrough-editor-open-file>.

## Check your setup (optional)

These are optional self-checks — read the output yourself; nothing here is
enforced automatically. MariaDB Cloud runs its own validation once this
setup is applied, so there's nothing you need to send back to us.

```bash
terraform output -json
```

```bash
gcloud compute project-info describe --project "$GOOGLE_CLOUD_PROJECT" --format=json \
  | jq -r '.commonInstanceMetadata.items[] | select(.key=="skysql-byoc-metadata") | .value' \
  | jq -S .
```

Compare `account_id`, `org_id` and `stack_id` in that output against
`terraform output byoc_metadata` — they should match.

If all of that looks right, you're done here — MariaDB Cloud will pick up the
new setup on its own. If something looks wrong, the output above is worth
copying into a support ticket.

## Coming back later

Use the same **Open in Cloud Shell** link again. Nothing is lost if this
Cloud Shell is gone: the state location is recoverable from the
`skysql-byoc-metadata` entry. Terraform will ask you again for your project
ID, MariaDB Cloud org ID and service account emails when you next run `plan`.

Re-export `$TF_VAR_state_bucket`/`$TF_VAR_state_prefix` first (see **Choose
where Terraform keeps its record** above), then re-run `terraform init` with
the same `-backend-config` flags (see **Connect Terraform** above) before
running `plan`/`apply` again.

**To allow a new region**, add it to the plan command:

```bash
terraform plan -out=tfplan \
  -var='allowed_regions=["us-central1","us-east1"]'
terraform apply tfplan
```

**To remove the setup**, once you have no MariaDB Cloud databases left in this
project: this removes the roles and permissions MariaDB Cloud uses in this
project, and deletes the `skysql-byoc-metadata` entry that MariaDB Cloud reads
to find your account. Do not do this while you still have MariaDB Cloud
databases running here.
The Terraform state bucket is not managed by Terraform and will be left in
place; delete it yourself once you are done.

```bash
terraform destroy
```

Terraform will show you the full destroy plan and ask you to type `yes`
before it removes anything — that's your confirmation gate.

## You're done

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

MariaDB Cloud now has the permissions it needs in
<walkthrough-project-id/>. Return to the MariaDB Cloud portal to launch your
first database.

Full reference documentation, including every variable, the exact roles
granted and troubleshooting, is in
<walkthrough-editor-open-file filePath="README.md">README.md</walkthrough-editor-open-file>.

<walkthrough-footnote>Need help? Contact MariaDB support with your project ID, <code>terraform output byoc_metadata</code>, and the <code>skysql-byoc-metadata</code> value from <code>gcloud compute project-info describe</code>.</walkthrough-footnote>
