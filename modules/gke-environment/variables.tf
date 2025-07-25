
variable "additional_cluster_sa_roles" {
  description = "Optional additional IAM roles to assign to the GKE cluster service account."
  type        = set(string)
  default     = []
}

variable "additional_gcp_project_services" {
  description = "Optional additional services to enable on the GCP project."
  type        = set(string)
  default     = []
}

variable "autopilot" {
  type        = bool
  default     = false
  description = "Whether to use GKE Autopilot cluster mode"
}

variable "blue_green_batch_percentage" {
  type        = number
  default     = 0.25
  description = "Percentage of nodes to upgrade in each batch for blue-green strategy"
  validation {
    condition     = var.blue_green_batch_percentage >= 0.0 && var.blue_green_batch_percentage <= 1.0
    error_message = "blue_green_batch_percentage must be between 0.0 and 1.0 (inclusive)."
  }
}

variable "cluster_autoscaling" {
  type        = bool
  default     = false
  description = "Determines whether node auto provisioning is enabled"
}

variable "cluster_master_cidr_block" {
  type        = string
  description = "The IP range in CIDR notation to use for the hosted master network"
}

variable "cluster_name" {
  type        = string
  description = "GKE Cluster name"
}

variable "cluster_sa_default_roles" {
  description = "Default IAM roles to bind to the GKE cluster service account."
  type        = set(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/storage.objectViewer"
  ]
}

variable "env_name" {
  type        = string
  description = "The environment name"
}

variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "gcp_project_services" {
  type        = set(string)
  description = "The list services to enable on the GCP project."
  default = [
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com"
  ]
}

variable "gcp_region" {
  type        = string
  description = "The GCP region"
}

variable "gke_maintenance_start_time" {
  type        = string
  description = "The start time of the daily maintenance window (HH:MM format)"
}

variable "gke_pods_subnet_cidr_range" {
  type        = string
  description = "The IP range in CIDR notation for GKE pods"
}

variable "gke_services_subnet_cidr_range" {
  type        = string
  description = "The IP range in CIDR notation for GKE services"
}

variable "gke_subnet_cidr_range" {
  type        = string
  description = "The IP range in CIDR notation for the GKE subnet"
}

variable "master_authorized_cidr_blocks" {
  type = list(object({
    display_name = string
    cidr_block   = string
  }))
  default     = []
  description = "List of CIDR blocks authorized to access the GKE master"
}

variable "nap_max_cpu" {
  type        = number
  default     = 1000
  description = "Maximum CPU cores for Node Auto Provisioning"
}

variable "nap_max_memory" {
  type        = number
  default     = 1000
  description = "Maximum memory in GB for Node Auto Provisioning"
}

variable "nap_max_surge" {
  type        = number
  default     = 1
  description = "Maximum number of nodes that can be created during surge upgrade"
}

variable "nap_min_cpu" {
  type        = number
  default     = 0
  description = "Minimum CPU cores for Node Auto Provisioning"
}

variable "nap_min_memory" {
  type        = number
  default     = 0
  description = "Minimum memory in GB for Node Auto Provisioning"
}

variable "nap_surge_max_unavailable" {
  type        = number
  default     = 0
  description = "Maximum number of nodes that can be unavailable during surge upgrade"
}

variable "node_pools" {
  type = map(object({
    machine_type   = string
    min_node_count = number
    max_node_count = number
    labels         = map(string)
    zones          = optional(list(string))
    preemptible    = optional(bool)
    spot           = optional(bool)
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default     = {}
  description = "Map of node pool configurations"
}

variable "node_tags" {
  type        = list(string)
  default     = []
  description = "List of network tags to apply to nodes"
}

variable "pods_secondary_range_name" {
  type        = string
  description = "The name of the secondary range for pod IPs"
}

variable "services_secondary_range_name" {
  type        = string
  description = "The name of the secondary range for service IPs"
}

variable "upgrade_strategy" {
  type        = string
  default     = "surge"
  description = "The upgrade strategy for node pools (surge or blue-green)"
  validation {
    condition     = contains(["surge", "blue-green"], var.upgrade_strategy)
    error_message = "upgrade_strategy must be either 'surge' or 'blue-green'."
  }
}

# Firewall configuration variables
variable "gke_control_plane_allowed_ports" {
  type = list(object({
    protocol = string
    ports    = list(string)
  }))
  default     = []
  description = "List of protocols and ports allowed from GKE control plane to worker nodes"
}








