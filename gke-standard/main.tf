# Terraform configuration with version requirements and GCS backend for state storage
terraform {
  required_version = "1.5.7"
  backend "gcs" {
    bucket = "<YOUR_PROJECT_ID>-tf-state"
    prefix = "platform/gke-standard"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.45.0"
    }
  }
}

# Configure Google Cloud provider with service account impersonation for secure authentication
provider "google" {
  project                     = var.gcp_project_id
  region                      = var.gcp_region
  impersonate_service_account = "terraform@<YOUR_PROJECT_ID>.iam.gserviceaccount.com"
}

# Assuming the GCP project is already created

# Define node pool configurations for different workload types
locals {
  node_pool_options = {
    "app-pool" = {
      min_node_count = 1
      max_node_count = 10
      machine_type   = "e2-standard-2"
      labels         = { role : "apps" }
    }

    "worker-pool" = {
      min_node_count = 0
      max_node_count = 15
      machine_type   = "c4-standard-2"
      spot           = true
      labels         = { role : "workers" }
      taints = [
        {
          key    = "workload",
          value  = "workers-spot",
          effect = "NO_SCHEDULE"
        },
        {
          key    = "workload",
          value  = "workers-spot",
          effect = "NO_EXECUTE"
        }
      ]
    }
  }
  # Define allowed ports for GKE control plane to worker node communication
  gke_control_plane_allowed_ports = [
    {
      protocol = "tcp"
      ports    = ["8443", "8000", "8089", "9443"]
    }
  ]
  # To connect to cluster using kubectl from Cloud Shell or localhost
  # master_authorized_cidr_blocks = [
  #   {
  #     "display_name" : "Cloud Shell CIDR"
  #     "cidr_block" : "<YOUR_CLOUD_SHELL_IP>/32"
  #   }
  # ]
}

# Instantiate the GKE environment module with all required configurations
module "gke_environment" {
  source = "../modules/gke-environment"

  # Environment configuration
  env_name = var.env_name

  # GCP configuration
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region

  # GKE cluster configuration
  cluster_name = "${var.env_name}-cluster"
  autopilot    = false

  # Network configuration
  gke_subnet_cidr_range          = var.gke_subnet_cidr_range
  gke_pods_subnet_cidr_range     = var.gke_pods_subnet_cidr_range
  gke_services_subnet_cidr_range = var.gke_services_subnet_cidr_range
  cluster_master_cidr_block      = var.cluster_master_cidr_block

  # Secondary range names (must match the names in the subnet configuration)
  pods_secondary_range_name     = "${var.env_name}-gke-pods"
  services_secondary_range_name = "${var.env_name}-gke-services"

  # Node pools configuration
  node_pools = local.node_pool_options

  # Cluster autoscaling
  cluster_autoscaling = true

  # Maintenance window
  gke_maintenance_start_time = var.gke_maintenance_start_time

  # Node tags for firewall rules
  node_tags = ["gke-manual-node"]

  # Firewall configuration
  gke_control_plane_allowed_ports = local.gke_control_plane_allowed_ports

}







