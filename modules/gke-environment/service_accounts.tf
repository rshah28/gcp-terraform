# This service account is used by the cluster and nodes to access GCP services
resource "google_service_account" "gke_cluster_sa" {
  project      = var.gcp_project_id
  account_id   = "${var.cluster_name}-sa"
  display_name = "GKE Cluster Service Account"
}

# Combine default and additional IAM roles for the cluster service account
locals {
  cluster_sa_all_roles = toset(flatten([
    var.cluster_sa_default_roles,
    var.additional_cluster_sa_roles
  ]))
}

# Assign IAM roles to the GKE cluster service account
resource "google_project_iam_member" "service_account-roles" {
  for_each = local.cluster_sa_all_roles
  project  = var.gcp_project_id
  role     = each.value
  member   = google_service_account.gke_cluster_sa.member
}
