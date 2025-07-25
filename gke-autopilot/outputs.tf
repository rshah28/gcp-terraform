# Cluster information
output "cluster_name" {
  description = "The name of the GKE Autopilot cluster"
  value       = module.gke_environment.cluster_name
}

output "cluster_endpoint" {
  description = "The IP address of the GKE Autopilot cluster master"
  value       = module.gke_environment.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate (base64 encoded)"
  value       = module.gke_environment.cluster_ca_certificate
  sensitive   = true
}

# Network information
output "network_name" {
  description = "The name of the VPC network"
  value       = module.gke_environment.network_name
}

output "subnet_name" {
  description = "The name of the GKE subnet"
  value       = module.gke_environment.subnet_name
}

# Service account information
output "cluster_service_account_email" {
  description = "The email address of the GKE cluster service account"
  value       = module.gke_environment.cluster_service_account_email
}

# Workload Identity Information
output "workload_identity_pool" {
  description = "The Workload Identity pool for the GKE cluster"
  value       = "${var.gcp_project_id}.svc.id.goog"
}

# Kubectl configuration command
output "kubectl_config_command" {
  description = "Command to configure kubectl for the GKE Autopilot cluster"
  value       = "gcloud container clusters get-credentials ${module.gke_environment.cluster_name} --region ${var.gcp_region} --project ${var.gcp_project_id}"
}

# Cluster dashboard URL
output "cluster_dashboard_url" {
  description = "URL to access the GKE Autopilot cluster in Google Cloud Console"
  value       = "https://console.cloud.google.com/kubernetes/clusters/details/${var.gcp_region}/${module.gke_environment.cluster_name}?project=${var.gcp_project_id}"
} 