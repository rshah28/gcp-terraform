# Essential GKE Cluster Information
output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke_environment.cluster_name
}

output "cluster_endpoint" {
  description = "The IP address of the GKE cluster master"
  value       = module.gke_environment.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate (base64 encoded)"
  value       = module.gke_environment.cluster_ca_certificate
  sensitive   = true
}

# Network Information
output "network_name" {
  description = "The name of the VPC network"
  value       = module.gke_environment.network_name
}

output "subnet_name" {
  description = "The name of the GKE subnet"
  value       = module.gke_environment.subnet_name
}

# Service Account Information
output "cluster_service_account_email" {
  description = "The email address of the GKE cluster service account"
  value       = module.gke_environment.cluster_service_account_email
}

# Node Pool Information
output "node_pool_names" {
  description = "The names of all GKE node pools"
  value       = module.gke_environment.node_pool_names
}

# Connection Information
output "kubectl_config_command" {
  description = "kubectl config command to configure access to the GKE cluster"
  value       = "gcloud container clusters get-credentials ${var.env_name}-cluster --region ${var.gcp_region} --project ${var.gcp_project_id}"
}

# Workload Identity Information
output "workload_identity_pool" {
  description = "The Workload Identity pool for the GKE cluster"
  value       = "${var.gcp_project_id}.svc.id.goog"
}
