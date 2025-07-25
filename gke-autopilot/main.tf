# Terraform configuration with version requirements and GCS backend for state storage
terraform {
  required_version = "1.5.7"
  backend "gcs" {
    bucket = "<YOUR_PROJECT_ID>-tf-state"
    prefix = "platform/gke-autopilot"
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

locals {
  # Example: Configure master authorized networks for secure access
  # Uncomment and modify as needed for your environment
  # master_authorized_cidr_blocks = [
  #   {
  #     display_name = "Cloud Shell CIDR"
  #     cidr_block   = "<YOUR_CLOUD_SHELL_IP>/32"
  #   }
  # ]
}

# Instantiate the GKE environment module with Autopilot configuration
module "gke_environment" {
  source = "../modules/gke-environment"

  # Environment configuration
  env_name = var.env_name

  # GCP configuration
  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region

  # GKE cluster configuration - Autopilot enabled
  cluster_name = "${var.env_name}-cluster"
  autopilot    = true # Enable Autopilot mode

  # Network configuration
  gke_subnet_cidr_range          = var.gke_subnet_cidr_range
  gke_pods_subnet_cidr_range     = var.gke_pods_subnet_cidr_range
  gke_services_subnet_cidr_range = var.gke_services_subnet_cidr_range
  cluster_master_cidr_block      = var.cluster_master_cidr_block

  # Secondary range names
  pods_secondary_range_name     = "${var.env_name}-gke-pods"
  services_secondary_range_name = "${var.env_name}-gke-services"

  # Cluster autoscaling - Always enabled in Autopilot
  cluster_autoscaling = true

  # Maintenance window
  gke_maintenance_start_time = var.gke_maintenance_start_time

  # Master authorized networks
  master_authorized_cidr_blocks = var.master_authorized_cidr_blocks
} 