variable "cluster_master_cidr_block" {
  type        = string
  description = "The IP range in CIDR notation to use for the hosted master network"
  default     = "10.20.0.0/28"
}

variable "env_name" {
  type        = string
  description = "The environment name"
  default     = "gke-standard-env"
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

# Node pool configurations
variable "node_pools" {
  type = map(object({
    min_node_count = number
    max_node_count = number
    machine_type   = string
    labels         = map(string)
    spot           = optional(bool, false)
    preemptible    = optional(bool, false)
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  description = "Node pool configurations for the GKE cluster"
  default = {
    "app-pool" = {
      min_node_count = 1
      max_node_count = 10
      machine_type   = "e2-standard-2"
      labels         = { role = "apps" }
    }
    "worker-pool" = {
      min_node_count = 0
      max_node_count = 15
      machine_type   = "c4-standard-2"
      spot           = true
      labels         = { role = "workers" }
      taints = [
        {
          key    = "workload"
          value  = "workers-spot"
          effect = "NO_SCHEDULE"
        },
        {
          key    = "workload"
          value  = "workers-spot"
          effect = "NO_EXECUTE"
        }
      ]
    }
  }
}

# Firewall configuration
variable "gke_control_plane_allowed_ports" {
  type = list(object({
    protocol = string
    ports    = list(string)
  }))
  description = "Ports allowed from GKE control plane to worker nodes"
  default = [
    {
      protocol = "tcp"
      ports    = ["8443", "8000", "8089", "9443"]
    }
  ]
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

variable "gke_pods_subnet_cidr_range" {
  type        = string
  description = "The IP range in CIDR notation for GKE pods"
  default     = "10.12.0.0/14"
}

variable "gke_services_subnet_cidr_range" {
  type        = string
  description = "The IP range in CIDR notation for GKE services"
  default     = "10.16.0.0/14"
}

variable "gke_subnet_cidr_range" {
  type        = string
  description = "The IP range in CIDR notation for the GKE subnet"
  default     = "10.0.0.0/20"
}

