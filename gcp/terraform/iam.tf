locals {
  address_prefixes = ["cl-org", "skysql"]

  cluster_conditions = [
    for region in var.allowed_regions :
    "resource.name.startsWith(\"projects/${var.project_id}/locations/${region}/clusters/cl-org\")"
  ]

  router_skysql_conditions = [
    for region in var.allowed_regions :
    "resource.name.startsWith(\"projects/${var.project_id}/regions/${region}/routers/skysql\")"
  ]

  subnetwork_cl_org_conditions = [
    for region in var.allowed_regions :
    "resource.name.startsWith(\"projects/${var.project_id}/regions/${region}/subnetworks/cl-org\")"
  ]

  subnetwork_db_conditions = [
    for region in var.allowed_regions :
    "resource.name.startsWith(\"projects/${var.project_id}/regions/${region}/subnetworks/db\")"
  ]

  address_conditions = flatten([
    for region in var.allowed_regions : [
      for prefix in local.address_prefixes :
      "resource.name.startsWith(\"projects/${var.project_id}/regions/${region}/addresses/${prefix}\")"
    ]
  ])

  firewall_prefixes = ["cl-org", "db", "skysql-"]

  firewall_conditions = [
    for prefix in local.firewall_prefixes :
    "resource.name.startsWith(\"projects/${var.project_id}/global/firewalls/${prefix}\")"
  ]
}

# Custom role for managing SkySQL Terraform state buckets and objects
resource "google_project_iam_custom_role" "skysql_storage" {
  role_id     = "SkySQLStoragee"
  title       = "SkySQL Storage Administrator"
  description = "Custom role for SkySQL orchestration to manage storage buckets and objects"
  permissions = [
    "storage.buckets.create",
    "storage.buckets.delete",
    "storage.buckets.get",
    "storage.buckets.getIamPolicy",
    "storage.buckets.setIamPolicy",
    "storage.buckets.update",
    "storage.multipartUploads.abort",
    "storage.multipartUploads.create",
    "storage.multipartUploads.list",
    "storage.multipartUploads.listParts",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.getIamPolicy",
    "storage.objects.list",
    "storage.objects.setIamPolicy",
    "storage.objects.update",
  ]
}

# Bind the custom role to the orchestration service account with a condition
# restricting access to buckets starting with the 'cl-org' or 'cl-sky' prefix.
resource "google_project_iam_member" "skysql_storage" {
  project = var.project_id
  role    = google_project_iam_custom_role.skysql_storage.id
  member  = "serviceAccount:${local.orchestration_sa_email}"

  condition {
    title       = "restrict_to_skysql_buckets"
    description = "Only allow access to buckets with cl-org prefix"
    expression  = "resource.name.startsWith(\"projects/_/buckets/cl-org\")"
  }
}

# Project-level permission to list buckets, necessary for Terraform to discover
# existing state buckets.
resource "google_project_iam_custom_role" "storage_lister" {
  role_id     = "SkySQLStorageLister"
  title       = "SkySQL Storage Lister"
  description = "Custom role for SkySQL orchestration to list buckets in the project"
  permissions = [
    "storage.buckets.list",
  ]
}

resource "google_project_iam_member" "storage_lister" {
  project = var.project_id
  role    = google_project_iam_custom_role.storage_lister.id
  member  = "serviceAccount:${local.orchestration_sa_email}"
}

# Project-level permission to create buckets. Like storage.buckets.list, the
# storage.buckets.create permission is evaluated against the project (there is
# no existing resource yet) and does NOT support resource.name IAM conditions:
# a binding whose condition references resource.name will not grant it. It must
# therefore be granted unconditioned, in its own minimal role.
resource "google_project_iam_custom_role" "storage_creator" {
  role_id     = "SkySQLStorageCreator"
  title       = "SkySQL Storage Creator"
  description = "Custom role for SkySQL to create storage buckets in the project"
  permissions = [
    "storage.buckets.create",
  ]
}

# Custom role for creating Workload Identity Pools and Providers
resource "google_project_iam_custom_role" "workload_identity_creator" {
  role_id     = "SkySQLWorkloadIdentityCreator"
  title       = "SkySQL Workload Identity Creator"
  description = "Custom role for SkySQL orchestration to create Workload Identity Pools and Providers"
  permissions = [
    "iam.workloadIdentityPools.create",
    "iam.workloadIdentityPoolProviders.create",
    "iam.workloadIdentityPools.get",
    "iam.workloadIdentityPoolProviders.get",
    "iam.workloadIdentityPools.delete",
    "iam.workloadIdentityPoolProviders.delete",
    "iam.workloadIdentityPools.getAttestationRules",
  ]
}

# Bind the creator role to the orchestration service account without a condition.
resource "google_project_iam_member" "workload_identity_creator" {
  project = var.project_id
  role    = google_project_iam_custom_role.workload_identity_creator.id
  member  = "serviceAccount:${local.orchestration_sa_email}"
}

# Custom role for IAM management (Delegated Granting)
resource "google_project_iam_custom_role" "sa_creator" {
  role_id     = "SkySQLSACreator"
  title       = "SkySQL Service Account Creator"
  description = "Custom role for SkySQL orchestration to manage Service Accounts creation"
  permissions = [
    "iam.serviceAccounts.create",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.list",
  ]
}

resource "google_project_iam_member" "sa_creator" {
  project = var.project_id
  role    = google_project_iam_custom_role.sa_creator.id
  member  = "serviceAccount:${local.orchestration_sa_email}"
}

# Custom role for creating GKE clusters and node pools
resource "google_project_iam_custom_role" "container_creator" {
  role_id     = "SkySQLContainerCreator"
  title       = "SkySQL Container Creator"
  description = "Custom role for SkySQL orchestration to create GKE clusters and node pools"
  permissions = [
    "container.clusters.create",
    "container.clusters.get",
    "container.operations.get",
    "container.clusters.list",
    "container.operations.list",
    "container.operations.list",
    "compute.zones.list",
    "compute.instanceGroupManagers.get",
    "compute.instanceGroupManagers.list",
    "compute.instances.get",
    "compute.instanceTemplates.get",
    "compute.machineTypes.get",
    "compute.instances.list",
    "compute.projects.get",
  ]
}

# Bind the creator role to the orchestration service account without a condition.
resource "google_project_iam_member" "container_creator" {
  project = var.project_id
  role    = google_project_iam_custom_role.container_creator.id
  member  = "serviceAccount:${local.orchestration_sa_email}"
}

# Grant the orchestration service account the ability to use the default compute service account
resource "google_service_account_iam_member" "default_compute_sa_user" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${local.orchestration_sa_email}"
  depends_on = [
    google_project_service.services
  ]
}

# Custom role for managing GKE clusters and node pools
resource "google_project_iam_custom_role" "container_admin" {
  role_id     = "SkySQLContainerAdmin"
  title       = "SkySQL Container Administrator"
  description = "Custom role for SkySQL orchestration to manage GKE clusters and node pools"
  permissions = [
    "container.clusters.delete",
    "container.clusters.update",
  ]
}
# Bind the custom role to the orchestration service account with a condition
# restricting access to clusters with the 'cl-org' prefix in any allowed region.
resource "google_project_iam_member" "container_admin" {
  project = var.project_id
  role    = google_project_iam_custom_role.container_admin.id
  member  = "serviceAccount:${local.orchestration_sa_email}"

  condition {
    title       = "restrict_to_skysql_clusters"
    description = "Only allow access to clusters with cl-org prefix"
    expression  = join(" || ", local.cluster_conditions)
  }
}

# Pre-defined role for the Cluster Controller Manager
# TODO Can this be constrained during the assignment?
resource "google_project_iam_custom_role" "controller_manager" {
  role_id     = "SkySQLControllerManager"
  title       = "SkySQL Controller Manager"
  description = "Permissions required by the SkySQL controller manager for snapshots and backups"
  permissions = [
    "compute.snapshots.create",
    "compute.snapshots.createTagBinding",
    "compute.snapshots.delete",
    "compute.snapshots.deleteTagBinding",
    "compute.snapshots.get",
    "compute.snapshots.list",
    "compute.snapshots.listTagBindings",
    "compute.snapshots.setLabels",
    "compute.snapshots.useReadOnly",
    "storage.buckets.create",
    "storage.buckets.createTagBinding",
    "storage.buckets.delete",
    "storage.buckets.deleteTagBinding",
    "storage.buckets.get",
    "storage.buckets.getIamPolicy",
    "storage.buckets.list",
    "storage.buckets.listTagBindings",
    "storage.buckets.setIamPolicy",
    "storage.buckets.update",
    "storage.multipartUploads.abort",
    "storage.multipartUploads.create",
    "storage.multipartUploads.list",
    "storage.multipartUploads.listParts",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.getIamPolicy",
    "storage.objects.list",
    "storage.objects.setIamPolicy",
    "storage.objects.update",
  ]
}

# Custom role for managing VPC networking resources
resource "google_project_iam_custom_role" "network_admin" {
  role_id     = "SkySQLNetworkAdmin"
  title       = "SkySQL Network Administrator"
  description = "Custom role for SkySQL orchestration to manage VPC networks, subnets, routers, and firewalls"
  permissions = [
    "compute.routers.create",
    "compute.routers.get",
    "compute.firewalls.create",
    "compute.firewalls.get",
    "compute.firewalls.list",
    "compute.addresses.list",
    "compute.routes.list",
    "compute.subnetworks.create",
    "compute.subnetworks.get",
    "compute.addresses.createInternal",
    "compute.addresses.get",
    "compute.addresses.create",
    "compute.networks.create",
    "compute.networks.get",
  ]
}

resource "google_project_iam_member" "network_admin" {
  project = var.project_id
  role    = google_project_iam_custom_role.network_admin.id
  member  = "serviceAccount:${local.orchestration_sa_email}"
}


# Custom role for managing VPC networking resources
resource "google_project_iam_custom_role" "network_cleanup" {
  role_id     = "SkySQLNetworkCleanup"
  title       = "SkySQL Network Cleanup"
  description = "Custom role for SkySQL orchestration to manage VPC networks, subnets, routers, and firewalls"
  permissions = [
    "compute.routers.delete",
    "compute.routers.update",
  ]
}

resource "google_project_iam_member" "network_cleanup" {
  project = var.project_id
  role    = google_project_iam_custom_role.network_cleanup.id
  member  = "serviceAccount:${local.orchestration_sa_email}"

  condition {
    title       = "restrict_to_skysql_network_resources"
    description = "Only allow managing networking resources with skysql prefix"
    expression  = join(" || ", local.router_skysql_conditions)
  }
}

# Custom role for IAM management (Delegated Granting)
resource "google_project_iam_custom_role" "iam_admin" {
  role_id     = "SkySQLIAMAdmin"
  title       = "SkySQL IAM Administrator"
  description = "Custom role for SkySQL orchestration to manage Service Accounts and grant specific roles"
  permissions = [
    "iam.serviceAccounts.delete",
    "iam.serviceAccounts.update",
    "iam.serviceAccounts.undelete",
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
  ]
}

resource "google_project_iam_member" "iam_admin" {
  project = var.project_id
  role    = google_project_iam_custom_role.iam_admin.id
  member  = "serviceAccount:${local.orchestration_sa_email}"

  condition {
    title       = "delegated_role_granting_and_skysql_sa_boundary"
    description = "Constrains IAM grants: allows only specific roles, restricts SA management to 'cm-skysql-' SAs, and project bindings to 'cm-skysql-' principals."
    expression  = "(api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly(['projects/${var.project_id}/roles/SkySQLControllerManager', 'roles/iam.workloadIdentityUser'])) && (!resource.name.startsWith('projects/${var.project_id}/serviceAccounts/') || resource.name.startsWith('projects/${var.project_id}/serviceAccounts/cm-skysql'))"
  }
}

resource "google_project_iam_custom_role" "iam_project_admin" {
  role_id     = "SkySQLIAMProjectAdmin"
  title       = "SkySQL IAM Administrator"
  description = "Custom role for SkySQL orchestration to manage Service Accounts and grant specific roles"
  permissions = [
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",
  ]
}

resource "google_project_iam_member" "iam_project_admin" {
  project = var.project_id
  role    = google_project_iam_custom_role.iam_project_admin.id
  member  = "serviceAccount:${local.orchestration_sa_email}"

  condition {
    title       = "Restrict_to_Project_and_SA"
    description = "Allows project-level IAM calls but restricts targets to specific SAs"

    expression = <<-EOT
      (resource.type == "cloudresourcemanager.googleapis.com/Project") || 
      (resource.type == "iam.googleapis.com/ServiceAccount" && 
       resource.name.startsWith("projects/${var.project_id}/serviceAccounts/cm-skysql"))
    EOT
  }
}

resource "google_project_iam_member" "orchestration_sa_k8s_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${local.orchestration_sa_email}"

  condition {
    title       = "restrict_to_skysql_clusters"
    description = "Grant admin on cl-org clusters and allow non-cluster discovery calls."
    expression  = <<EOT
      (resource.type != 'container.googleapis.com/Cluster' && resource.type != 'container.googleapis.com/NodePool') ||
      (${join(" || ", local.cluster_conditions)})
    EOT
  }
}

resource "google_project_iam_member" "federated_manager_sa_k8s_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${local.federated_manager_sa_email}"

  condition {
    title       = "restrict_to_skysql_clusters"
    description = "Grant admin on cl-org clusters and allow non-cluster discovery calls."
    expression  = <<EOT
      (resource.type != 'container.googleapis.com/Cluster' && resource.type != 'container.googleapis.com/NodePool') ||
      (${join(" || ", local.cluster_conditions)})
    EOT
  }
}

resource "google_project_iam_member" "backup_service_sa_k8s_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${local.backup_sa_email}"

  condition {
    title       = "restrict_to_skysql_clusters"
    description = "Grant admin on cl-org clusters and allow non-cluster discovery calls."
    expression  = <<EOT
      (resource.type != 'container.googleapis.com/Cluster' && resource.type != 'container.googleapis.com/NodePool') ||
      (${join(" || ", local.cluster_conditions)})
    EOT
  }
}

# Custom role for updating the default VPC network policy
resource "google_project_iam_custom_role" "default_network_updater" {
  role_id     = "SkySQLDefaultNetworkUpdater"
  title       = "SkySQL Default Network Updater"
  description = "Custom role for SkySQL orchestration to update the default VPC network policy"
  permissions = [
    "compute.networks.updatePolicy",
    "compute.networks.delete",
  ]
}

resource "google_project_iam_member" "default_network_updater" {
  project = var.project_id
  role    = google_project_iam_custom_role.default_network_updater.id
  member  = "serviceAccount:${local.orchestration_sa_email}"

  condition {
    title       = "restrict_to_default_network"
    description = "Only allow updating the default network policy"
    expression  = "resource.name.startsWith(\"projects/${var.project_id}/global/networks/cl-org\")"
  }
}

# Custom role for using the default subnetwork
resource "google_project_iam_custom_role" "default_subnetwork_user" {
  role_id     = "SkySQLDefaultSubnetworkUser"
  title       = "SkySQL Default Subnetwork User"
  description = "Custom role for SkySQL orchestration to use the default subnetwork"
  permissions = [
    "compute.subnetworks.use",
    "compute.subnetworks.delete"
  ]
}

resource "google_project_iam_member" "default_subnetwork_user" {
  project = var.project_id
  role    = google_project_iam_custom_role.default_subnetwork_user.id
  member  = "serviceAccount:${local.orchestration_sa_email}"

  condition {
    title       = "restrict_to_default_subnetwork"
    description = "Only allow using subnetworks with the cl-org prefix in any allowed region"
    expression  = join(" || ", local.subnetwork_cl_org_conditions)
  }
}

# Custom role for managing firewall rules (delete + update)
resource "google_project_iam_custom_role" "firewall_manager" {
  role_id     = "SkySQLFirewallManager"
  title       = "SkySQL Firewall Manager"
  description = "Custom role for SkySQL orchestration to delete and update firewall rules"
  permissions = [
    "compute.firewalls.delete",
    "compute.firewalls.update",
  ]
}

resource "google_project_iam_member" "firewall_manager" {
  project = var.project_id
  role    = google_project_iam_custom_role.firewall_manager.id
  member  = "serviceAccount:${local.orchestration_sa_email}"

  condition {
    title       = "restrict_to_skysql_firewalls"
    description = "Only allow managing firewalls with the cl-org, db, or skysql- prefix"
    expression  = join(" || ", local.firewall_conditions)
  }
}

# Custom role for managing address labels
resource "google_project_iam_custom_role" "address_labeler" {
  role_id     = "SkySQLAddressLabeler"
  title       = "SkySQL Address Labeler"
  description = "Custom role for SkySQL orchestration to set labels on addresses"
  permissions = [
    "compute.addresses.setLabels",
    "compute.addresses.deleteInternal",
    "compute.addresses.delete",
  ]
}

resource "google_project_iam_member" "address_labeler" {
  project = var.project_id
  role    = google_project_iam_custom_role.address_labeler.id
  member  = "serviceAccount:${local.orchestration_sa_email}"

  condition {
    title       = "restrict_to_cl_org_addresses"
    description = "Only allow setting labels on addresses with the cl-org or skysql prefix in any allowed region"
    expression  = join(" || ", local.address_conditions)
  }
}

# Custom role for managing database subnetwork rules
resource "google_project_iam_custom_role" "db_subnetwork_manager" {
  role_id     = "SkySQLDBSubnetworkManager"
  title       = "SkySQL DB Subnetwork Manager"
  description = "Custom role for SkySQL orchestration to delete subnetwork rules with the db prefix"
  permissions = [
    "compute.subnetworks.delete",
  ]
}

resource "google_project_iam_member" "db_subnetwork_manager" {
  project = var.project_id
  role    = google_project_iam_custom_role.db_subnetwork_manager.id
  member  = "serviceAccount:${local.orchestration_sa_email}"

  condition {
    title       = "restrict_to_db_subnetworks"
    description = "Only allow deleting subnetworks with the db prefix in any allowed region"
    expression  = join(" || ", local.subnetwork_db_conditions)
  }
}

# Pre-defined role attached at runtime by the backup service to the per-backup
# pod service accounts. Created here but intentionally left unbound.
resource "google_project_iam_custom_role" "backup_pod" {
  role_id     = "SkySQLBackupPod"
  title       = "SkySQL Backup Pod"
  description = "Storage permissions granted to SkySQL backup pod service accounts to read and write backups"
  permissions = [
    "storage.objects.create",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.delete",
    "storage.buckets.get",
  ]
}

# Backup service account permissions. Rather than a bespoke role, the backup SA
# reuses the existing orchestration roles, scoped with the same condition idiom
# each of those roles already uses on its sibling binding.

# Backup service: create/read backup pod service accounts.
resource "google_project_iam_member" "backup_sa_creator" {
  project = var.project_id
  role    = google_project_iam_custom_role.sa_creator.id
  member  = "serviceAccount:${local.backup_sa_email}"
}

# Backup service: manage IAM policy on 'skysql' SAs and grant only the
# BackupPod / workloadIdentityUser roles to them.
resource "google_project_iam_member" "backup_iam_admin" {
  project = var.project_id
  role    = google_project_iam_custom_role.iam_admin.id
  member  = "serviceAccount:${local.backup_sa_email}"

  condition {
    title       = "delegated_role_granting_and_skysql_sa_boundary"
    description = "Constrains IAM grants to BackupPod/workloadIdentityUser and restricts SA management to 'skysql' SAs."
    expression  = "(api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly(['projects/${var.project_id}/roles/SkySQLBackupPod', 'roles/iam.workloadIdentityUser'])) && (!resource.name.startsWith('projects/${var.project_id}/serviceAccounts/') || resource.name.startsWith('projects/${var.project_id}/serviceAccounts/skysql'))"
  }
}

# Backup service: manage this project's backup buckets/objects (named
# '<project_id>-backup-*'); bucket IAM grants restricted to the BackupPod /
# workloadIdentityUser roles.
resource "google_project_iam_member" "backup_storage" {
  project = var.project_id
  role    = google_project_iam_custom_role.skysql_storage.id
  member  = "serviceAccount:${local.backup_sa_email}"

  condition {
    title       = "restrict_to_backup_buckets_and_backup_grants"
    description = "Only allow access to this project's '<project_id>-backup-' buckets; bucket IAM grants limited to BackupPod/workloadIdentityUser."
    expression  = "(api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly(['projects/${var.project_id}/roles/SkySQLBackupPod', 'roles/iam.workloadIdentityUser'])) && resource.name.startsWith(\"projects/_/buckets/${var.project_id}-backup-\")"
  }
}

# Backup service: create buckets. storage.buckets.create cannot be scoped by
# bucket name (project-level permission, see storage_creator), so it is granted
# unconditioned. Once created (as '<project_id>-backup-*' buckets),
# management/IAM is governed by the conditioned backup_storage binding above.
resource "google_project_iam_member" "backup_storage_creator" {
  project = var.project_id
  role    = google_project_iam_custom_role.storage_creator.id
  member  = "serviceAccount:${local.backup_sa_email}"
}

resource "google_logging_log_view" "cluster_logs" {
  name        = "skysql-cluster-logs"
  bucket      = "projects/${var.project_id}/locations/global/buckets/_Default"
  description = "SkySQL GKE cluster logs only."
  filter      = "resource.labels.cluster_name=~\"^cl-org\""
}

resource "google_project_iam_member" "cluster_log_view_accessor" {
  project = var.project_id
  role    = "roles/logging.viewAccessor"
  member  = "serviceAccount:${local.orchestration_sa_email}"

  condition {
    title       = "restrict_to_skysql_log_view"
    description = "Only allow reading the SkySQL cluster log view"
    expression  = "resource.name == \"projects/${var.project_id}/locations/global/buckets/_Default/views/${google_logging_log_view.cluster_logs.name}\""
  }
}

# Cloud Monitoring has no resource-level IAM, so this is scoped down to alert reads only.
resource "google_project_iam_custom_role" "monitoring_viewer" {
  role_id     = "SkySQLMonitoringViewer"
  title       = "SkySQL Monitoring Viewer"
  description = "Read-only access to Cloud Monitoring alert-policy configs. Excludes notificationChannels (customer PII) and timeSeries/metricDescriptors (customer metric data)."
  permissions = [
    "monitoring.alertPolicies.get",
    "monitoring.alertPolicies.list",
    "monitoring.alerts.list",
    "monitoring.timeSeries.list"
  ]
}

resource "google_project_iam_member" "monitoring_viewer" {
  project = var.project_id
  role    = google_project_iam_custom_role.monitoring_viewer.id
  member  = "serviceAccount:${local.orchestration_sa_email}"
}
