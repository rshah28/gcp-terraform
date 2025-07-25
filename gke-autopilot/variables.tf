variable "cluster_master_cidr_block" {
  type        = string
  description = "The IP range in CIDR notation to use for the hosted master network"
  default     = "10.30.0.0/28"
}

variable "env_name" {
  type        = string
  description = "The environment name"
  default     = "gke-autopilot-env"
}

variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID"
  default     = "<YOUR_PROJECT_ID>"
}

variable "gcp_region" {
  type        = string
  description = "The GCP region"
  default     = "us-central1"
}

variable "gke_maintenance_start_time" {
  type        = string
  description = "The start time of the daily maintenance window (HH:MM format)"
  default     = "05:00"
}

variable "gke_pods_subnet_cidr_range" {
  type        = string
  description = "The IP range in CIDR notation for GKE pods"
  default     = "10.32.0.0/14" 
}

variable "gke_services_subnet_cidr_range" {
  type        = string
  description = "The IP range in CIDR notation for GKE services"
  default     = "10.36.0.0/14" 
}

variable "gke_subnet_cidr_range" {
  type        = string
  description = "The IP range in CIDR notation for the GKE subnet"
  default     = "10.24.0.0/20" 
}

# Master authorized networks
variable "master_authorized_cidr_blocks" {
  type = list(object({
    display_name = string
    cidr_block   = string
  }))
  description = "CIDR blocks authorized to access the GKE master"
  default     = []
} 