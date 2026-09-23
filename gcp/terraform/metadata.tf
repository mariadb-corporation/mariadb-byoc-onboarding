# -----------------------------------------------------------------------------
# Compute project metadata: BYOC deployment metadata
# -----------------------------------------------------------------------------

resource "google_compute_project_metadata_item" "byoc_metadata" {
  project = var.project_id
  key     = local.metadata_key
  value   = jsonencode(local.metadata)

  depends_on = [
    google_project_service.services,
    google_project_iam_member.skysql_storage,
    google_project_iam_member.storage_lister,
    google_project_iam_member.workload_identity_creator,
    google_project_iam_member.sa_creator,
    google_project_iam_member.container_creator,
    google_project_iam_member.container_admin,
    google_project_iam_member.network_admin,
    google_project_iam_member.network_cleanup,
    google_project_iam_member.iam_admin,
    google_project_iam_member.iam_project_admin,
    google_project_iam_member.orchestration_sa_k8s_admin,
    google_project_iam_member.federated_manager_sa_k8s_admin,
    google_project_iam_member.backup_service_sa_k8s_admin,
    google_project_iam_member.default_network_updater,
    google_project_iam_member.default_subnetwork_user,
    google_project_iam_member.firewall_manager,
    google_project_iam_member.address_labeler,
    google_project_iam_member.db_subnetwork_manager,
    google_project_iam_member.backup_sa_creator,
    google_project_iam_member.backup_iam_admin,
    google_project_iam_member.backup_storage,
    google_project_iam_member.backup_storage_creator,
    google_project_iam_member.cluster_log_view_accessor,
    google_project_iam_member.monitoring_viewer,
    google_service_account_iam_member.default_compute_sa_user,
    google_project_iam_custom_role.controller_manager,
    google_project_iam_custom_role.backup_pod,
  ]
}
