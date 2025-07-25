# GKE Environment Module

This Terraform module creates a complete Google Kubernetes Engine (GKE) environment with networking, security, and infrastructure components. It supports both GKE Standard and GKE Autopilot clusters with configurable node pools, firewall rules, and networking.

## Features

- **GKE Cluster**: Standard or Autopilot mode with configurable settings
- **Networking**: VPC, subnets, Cloud Router, and NAT Gateway
- **Security**: Service accounts, IAM roles, and firewall rules
- **Node Pools**: Configurable node pools with autoscaling
- **Firewall**: Modular firewall rules for control plane access
- **Workload Identity**: Built-in Workload Identity support

## Usage

### Basic Usage

```hcl
module "gke_environment" {
  source = "../modules/gke-environment"

  # Environment configuration
  env_name = "production"
  
  # GCP configuration
  gcp_project_id = "my-project-id"
  gcp_region     = "us-central1"

  # GKE cluster configuration
  cluster_name = "production-cluster"
  autopilot    = false

  # Network configuration
  gke_subnet_cidr_range          = "10.0.0.0/20"
  gke_pods_subnet_cidr_range     = "10.12.0.0/14"
  gke_services_subnet_cidr_range = "10.16.0.0/14"
  cluster_master_cidr_block      = "10.20.0.0/28"

  # Secondary range names
  pods_secondary_range_name     = "production-gke-pods"
  services_secondary_range_name = "production-gke-services"

  # Node pools configuration
  node_pools = {
    "default-pool" = {
      machine_type   = "e2-standard-4"
      min_node_count = 1
      max_node_count = 5
      labels = {
        environment = "production"
        node-pool   = "default"
      }
    }
  }

  # Cluster autoscaling
  cluster_autoscaling = true

  # Maintenance window
  gke_maintenance_start_time = "02:00"

  # Node tags for firewall rules
  node_tags = ["gke-node", "production"]

  # Firewall configuration
  gke_control_plane_allowed_ports = [
    {
      protocol = "tcp"
      ports    = ["8443", "8000", "8089", "9443"]
    }
  ]
}
```

### GKE Autopilot Usage

```hcl
module "gke_environment" {
  source = "../modules/gke-environment"

  env_name = "development"
  
  gcp_project_id = "my-project-id"
  gcp_region     = "us-central1"

  cluster_name = "development-cluster"
  autopilot    = true  # Enable Autopilot mode

  # Network configuration (still required for Autopilot)
  gke_subnet_cidr_range          = "10.0.0.0/20"
  gke_pods_subnet_cidr_range     = "10.12.0.0/14"
  gke_services_subnet_cidr_range = "10.16.0.0/14"
  cluster_master_cidr_block      = "10.20.0.0/28"

  pods_secondary_range_name     = "development-gke-pods"
  services_secondary_range_name = "development-gke-services"

  # No node_pools needed for Autopilot
  # Firewall rules are automatically managed
}
```

## Inputs

### Required Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `env_name` | The environment name | `string` | n/a |
| `gcp_project_id` | The GCP project ID | `string` | n/a |
| `gcp_region` | The GCP region | `string` | n/a |
| `cluster_name` | GKE Cluster name | `string` | n/a |
| `cluster_master_cidr_block` | The IP range in CIDR notation to use for the hosted master network | `string` | n/a |
| `gke_subnet_cidr_range` | The IP range in CIDR notation for the GKE subnet | `string` | n/a |
| `gke_pods_subnet_cidr_range` | The IP range in CIDR notation for GKE pods | `string` | n/a |
| `gke_services_subnet_cidr_range` | The IP range in CIDR notation for GKE services | `string` | n/a |
| `pods_secondary_range_name` | The name of the secondary range for pod IPs | `string` | n/a |
| `services_secondary_range_name` | The name of the secondary range for service IPs | `string` | n/a |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `autopilot` | Whether to use GKE Autopilot cluster mode | `bool` | `false` |
| `cluster_autoscaling` | Determines whether node auto provisioning is enabled | `bool` | `false` |
| `node_pools` | Map of node pool configurations | `map(object)` | `{}` |
| `gke_maintenance_start_time` | The start time of the daily maintenance window (HH:MM format) | `string` | n/a |
| `node_tags` | List of network tags to apply to nodes | `list(string)` | `[]` |
| `gke_control_plane_allowed_ports` | List of protocols and ports allowed from GKE control plane to worker nodes | `list(object)` | `[]` |
| `gke_control_plane_target_tags` | Network tags for nodes that should be accessible from GKE control plane | `list(string)` | `["internal-ingress"]` |
| `availability_zones` | List of availability zones to use for node pools | `list(string)` | `["a", "b", "c"]` |
| `master_authorized_cidr_blocks` | List of CIDR blocks authorized to access the GKE master | `list(object)` | `[]` |
| `cluster_sa_default_roles` | Default IAM roles to bind to the GKE cluster service account | `set(string)` | `["roles/logging.logWriter", "roles/monitoring.metricWriter", "roles/monitoring.viewer", "roles/storage.objectViewer"]` |
| `additional_cluster_sa_roles` | Optional additional IAM roles to assign to the GKE cluster service account | `set(string)` | `[]` |
| `gcp_project_services` | The list services to enable on the GCP project | `set(string)` | See variables.tf |
| `upgrade_strategy` | The upgrade strategy for node pools (surge or blue-green) | `string` | `"surge"` |

### Node Pool Configuration

```hcl
node_pools = {
  "app-pool" = {
    machine_type   = "e2-standard-4"
    min_node_count = 1
    max_node_count = 10
    labels = {
      role = "apps"
    }
    zones = ["us-central1-a", "us-central1-b"]  # Optional
    preemptible = false  # Optional
    spot = false         # Optional
    taints = [           # Optional
      {
        key    = "workload"
        value  = "apps"
        effect = "NO_SCHEDULE"
      }
    ]
  }
}
```

### Firewall Configuration

```hcl
gke_control_plane_allowed_ports = [
  {
    protocol = "tcp"
    ports    = ["8443", "8000", "8089", "9443"]
  },
  {
    protocol = "udp"
    ports    = ["8125"]
  }
]
```

## Outputs

| Name | Description |
|------|-------------|
| `cluster_name` | The name of the GKE cluster |
| `cluster_endpoint` | The IP address of the GKE cluster master |
| `cluster_ca_certificate` | The cluster CA certificate (base64 encoded) |
| `network_name` | The name of the VPC network |
| `subnet_name` | The name of the GKE subnet |
| `cluster_service_account_email` | The email address of the GKE cluster service account |
| `node_pool_names` | The names of all GKE node pools |
| `gke_control_plane_firewall_name` | Name of the GKE control plane firewall rule |

## Network Architecture

The module creates a complete networking stack:

```
VPC Network
├── GKE Subnet (10.0.0.0/20)
│   ├── Pods Secondary Range (10.12.0.0/14)
│   └── Services Secondary Range (10.16.0.0/14)
├── Cloud Router
└── NAT Gateway (for outbound internet access)
```

## Security Features

### Service Account
- Creates a dedicated service account for the GKE cluster
- Assigns default roles for logging, monitoring, and storage
- Supports additional custom roles

### Firewall Rules
- Control plane access to worker nodes (configurable ports)
- Only created for GKE Standard clusters (Autopilot manages automatically)

### Private Cluster
- Nodes have only internal IP addresses
- Master endpoint can be public or private
- Configurable authorized networks

## Examples

### Production Environment

```hcl
module "gke_production" {
  source = "../modules/gke-environment"

  env_name = "production"
  gcp_project_id = "my-production-project"
  gcp_region = "us-central1"

  cluster_name = "production-cluster"
  autopilot = false

  # Network configuration
  gke_subnet_cidr_range = "10.0.0.0/20"
  gke_pods_subnet_cidr_range = "10.12.0.0/14"
  gke_services_subnet_cidr_range = "10.16.0.0/14"
  cluster_master_cidr_block = "10.20.0.0/28"

  pods_secondary_range_name = "production-gke-pods"
  services_secondary_range_name = "production-gke-services"

  # Node pools
  node_pools = {
    "app-pool" = {
      machine_type = "e2-standard-4"
      min_node_count = 2
      max_node_count = 10
      labels = { role = "apps" }
    }
    "worker-pool" = {
      machine_type = "c2-standard-4"
      min_node_count = 1
      max_node_count = 5
      spot = true
      labels = { role = "workers" }
    }
  }

  cluster_autoscaling = true
  gke_maintenance_start_time = "02:00"
  node_tags = ["gke-node", "production"]

  # Firewall
  gke_control_plane_allowed_ports = [
    {
      protocol = "tcp"
      ports = ["8443", "8000", "8089", "9443", "10250"]
    }
  ]
}
```

### Development Environment

```hcl
module "gke_development" {
  source = "../modules/gke-environment"

  env_name = "development"
  gcp_project_id = "my-dev-project"
  gcp_region = "us-central1"

  cluster_name = "dev-cluster"
  autopilot = true  # Use Autopilot for development

  # Network configuration
  gke_subnet_cidr_range = "172.16.0.0/20"
  gke_pods_subnet_cidr_range = "172.20.0.0/16"
  gke_services_subnet_cidr_range = "172.24.0.0/16"
  cluster_master_cidr_block = "172.28.0.0/28"

  pods_secondary_range_name = "dev-gke-pods"
  services_secondary_range_name = "dev-gke-services"

  gke_maintenance_start_time = "05:00"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.7 |
| google | >= 6.45.0 |

## Providers

| Name | Version |
|------|---------|
| google | 6.45.0 |

## Notes

- GKE Autopilot clusters automatically manage node pools and some firewall rules
- The module creates a private cluster by default for security
- Workload Identity is enabled by default for secure pod-to-service authentication
- All resources include proper dependencies and lifecycle management
- The module supports both regional and zonal clusters
