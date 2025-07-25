# GKE Cluster Information
output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = var.cluster_name
}

output "cluster_endpoint" {
  description = "The IP address of the GKE cluster master"
  value       = var.autopilot ? google_container_cluster.gke_autopilot_cluster[0].endpoint : google_container_cluster.gke_standard_cluster[0].endpoint
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate (base64 encoded)"
  value       = var.autopilot ? google_container_cluster.gke_autopilot_cluster[0].master_auth[0].cluster_ca_certificate : google_container_cluster.gke_standard_cluster[0].master_auth[0].cluster_ca_certificate
  sensitive   = true
}

# Network Information
output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.default.name
}

output "subnet_name" {
  description = "The name of the GKE subnet"
  value       = google_compute_subnetwork.gke.name
}

# Service Account Information
output "cluster_service_account_email" {
  description = "The email address of the GKE cluster service account"
  value       = google_service_account.gke_cluster_sa.email
}

# Node Pool Information
output "node_pool_names" {
  description = "The names of all GKE node pools"
  value       = keys(google_container_node_pool.node_pool)
}

# Firewall Information
output "gke_control_plane_firewall_name" {
  description = "Name of the GKE control plane firewall rule"
  value       = length(google_compute_firewall.gke_control_plane_node_access) > 0 ? google_compute_firewall.gke_control_plane_node_access[0].name : null
}
