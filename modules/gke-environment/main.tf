# Configure the Google Cloud provider for Terraform
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.45.0"
    }
  }
}

# Combine default and additional GCP project services
locals {
  all_gcp_project_services = toset(flatten([
    var.gcp_project_services,
    var.additional_gcp_project_services
  ]))
}

# Enable required Google Cloud APIs and services
resource "google_project_service" "project_service" {
  for_each                   = local.all_gcp_project_services
  project                    = var.gcp_project_id
  service                    = each.value
  disable_dependent_services = false
  disable_on_destroy         = false
}

