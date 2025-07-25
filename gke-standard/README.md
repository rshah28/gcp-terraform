# GKE Standard Environment

This directory contains the Terraform configuration for a Google Kubernetes Engine (GKE) Standard cluster with comprehensive networking, security, and infrastructure components.

## Prerequisites

Before deploying this environment, ensure you have completed all prerequisites listed in the [main repository README](../README.md#prerequisites).

The prerequisites include:
- Creating a Terraform service account
- Configuring service account impersonation
- Creating GCS bucket for Terraform state
- Assigning required IAM roles
- Enabling necessary Google Cloud APIs
- Setting up authentication
- Configuring master authorized networks for cluster access

For detailed step-by-step instructions, see the [GCP Setup Requirements](../README.md#gcp-setup-requirements) section in the main README.

### Required Tools

- **Terraform**: Version >= 1.5.7
- **Google Cloud SDK**: Latest version
- **kubectl**: For Kubernetes cluster management (optional but recommended)

### Assumptions

- ✅ GCP Project is already created and billing is enabled
- ✅ Organization-level resources are already configured
- ✅ User has appropriate permissions to create and manage resources

## Overview

The GKE Standard environment provides:
- **GKE Standard Cluster**: Full control over node pools and cluster configuration
- **Multi-Node Pool Architecture**: Separate pools for applications and workers
- **Spot Instances**: Cost optimization with spot instances for worker workloads
- **Private Networking**: Secure VPC-native cluster with private nodes
- **Modular Firewall**: Configurable firewall rules for control plane access
- **Workload Identity**: Secure pod-to-service authentication
- **Master Authorized Networks**: Secure access to the GKE control plane

## Architecture

```
GKE Standard Cluster
├── App Pool (e2-standard-2)
│   ├── Min: 1 node, Max: 10 nodes
│   ├── On-demand instances
│   └── Role: applications
└── Worker Pool (c4-standard-2)
    ├── Min: 0 nodes, Max: 15 nodes
    ├── Spot instances (cost optimized)
    ├── Taints: workload=workers-spot
    └── Role: batch processing, background jobs
```

## Deployment

### 1. Configure Environment

Update the configuration files with your specific values:

#### Update `variables.tf`

```hcl
variable "gcp_project_id" {
  type        = string
  description = "The GCP project ID"
  # Remove default - you must provide your project ID
}

variable "gcp_region" {
  type        = string
  description = "The GCP region"
  # Remove default - you must provide your region
}

variable "env_name" {
  type        = string
  description = "Environment name"
  # Remove default - you must provide your environment name
}

variable "master_authorized_networks_config" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  description = "List of CIDR blocks authorized to access the GKE control plane"
  # You must add your IP address here
}
```

#### Update `main.tf`

```hcl
terraform {
  required_version = "1.5.7"
  backend "gcs" {
    bucket = "your-project-terraform-state"  # Update with your bucket
    prefix = "platform/gke-standard"         # Update with your prefix
  }
}

provider "google" {
  project                     = var.gcp_project_id
  region                      = var.gcp_region
  impersonate_service_account = "terraform@your-project-id.iam.gserviceaccount.com"  # Update with your SA
}
```

#### Configure Master Authorized Networks

To access the cluster, configure your IP address:

```bash
# Get your public IP address
export YOUR_IP=$(curl -s ifconfig.me)

# Update the master_authorized_networks_config variable in variables.tf
```

Example configuration:
```hcl
variable "master_authorized_networks_config" {
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  description = "List of CIDR blocks authorized to access the GKE control plane"
  default = [
    {
      cidr_block   = "203.0.113.0/32"  # Replace with your IP
      display_name = "Local Development"
    }
  ]
}
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the planned changes
terraform plan

# Apply the configuration
terraform apply

# Confirm the deployment when prompted
```

### 3. Configure kubectl

```bash
# Use the output command
terraform output kubectl_config_command

# Or run directly
gcloud container clusters get-credentials <cluster-name> \
  --region <region> \
  --project <project-id>
```

## Configuration

### Required Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `env_name` | Environment name | Yes |
| `gcp_project_id` | GCP Project ID | Yes |
| `gcp_region` | GCP Region | Yes |
| `gke_subnet_cidr_range` | GKE subnet CIDR | Yes |
| `gke_pods_subnet_cidr_range` | Pods subnet CIDR | Yes |
| `gke_services_subnet_cidr_range` | Services subnet CIDR | Yes |
| `cluster_master_cidr_block` | Master CIDR block | Yes |
| `gke_maintenance_start_time` | Maintenance window | Yes |
| `master_authorized_networks_config` | Authorized networks for cluster access | Yes |

### Node Pools

#### App Pool
- **Machine Type**: `e2-standard-2` (cost-effective)
- **Scaling**: 1-10 nodes
- **Instance Type**: On-demand
- **Purpose**: Application workloads, web services

#### Worker Pool
- **Machine Type**: `c4-standard-2` (compute-optimized)
- **Scaling**: 0-15 nodes
- **Instance Type**: Spot instances (up to 60% cost savings)
- **Taints**: `workload=workers-spot:NoSchedule`
- **Purpose**: Batch processing, background jobs, CI/CD

### Network Configuration

#### CIDR Ranges
You must configure these CIDR ranges in your `variables.tf`:

- **GKE Subnet**: `10.0.0.0/20` (4,096 IPs)
- **Pods**: `10.12.0.0/14` (262,144 IPs)
- **Services**: `10.16.0.0/14` (262,144 IPs)
- **Master**: `10.20.0.0/28` (16 IPs)

#### Security
- **Private Cluster**: Nodes have only internal IPs
- **Public Master**: Master endpoint is publicly accessible
- **Firewall**: Control plane access on specific ports only
- **Master Authorized Networks**: Only configured IPs can access the control plane

## Usage Examples

### Deploy Applications

```yaml
# Deploy to app pool (default)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: nginx:latest
        ports:
        - containerPort: 80
```

### Deploy to Worker Pool

```yaml
# Deploy to worker pool (spot instances)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-job
spec:
  replicas: 5
  selector:
    matchLabels:
      app: batch-job
  template:
    metadata:
      labels:
        app: batch-job
    spec:
      tolerations:
      - key: "workload"
        operator: "Equal"
        value: "workers-spot"
        effect: "NoSchedule"
      containers:
      - name: batch-job
        image: my-batch-job:latest
```

### Service Account with Workload Identity

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
  annotations:
    iam.gke.io/gcp-service-account: my-app@your-project-id.iam.gserviceaccount.com
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      serviceAccountName: my-app-sa
      containers:
      - name: app
        image: my-app:latest
```

## Monitoring and Logging

### Cluster Monitoring
- **Cloud Monitoring**: Enabled by default
- **Cloud Logging**: Enabled by default
- **Service Account**: Has monitoring and logging permissions

### Access Logs
```bash
# View cluster logs
gcloud logging read "resource.type=gke_cluster AND resource.labels.cluster_name=<cluster-name>"

# View node pool logs
gcloud logging read "resource.type=gce_instance AND resource.labels.cluster_name=<cluster-name>"
```

## Maintenance

### Cluster Updates
- **Maintenance Window**: Configurable (default: 05:00 UTC daily)
- **Auto-upgrade**: Enabled for node pools
- **Auto-repair**: Enabled for node pools

### Scaling
- **Cluster Autoscaling**: Enabled
- **Node Auto Provisioning**: Enabled

### Useful Commands

```bash
# Get cluster info
kubectl cluster-info

# Check node pools
kubectl get nodes -o wide

# Check taints and tolerations
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# Check service accounts
kubectl get serviceaccounts

# Check firewall rules
gcloud compute firewall-rules list --filter="name~<cluster-name>"
```

## Outputs

After deployment, useful outputs are available:

```bash
# Get cluster endpoint
terraform output cluster_endpoint

# Get service account email
terraform output cluster_service_account_email

# Get kubectl config command
terraform output kubectl_config_command

# Get workload identity pool
terraform output workload_identity_pool
```

## Security Considerations

- **Private Cluster**: Nodes are not directly accessible from internet
- **Service Account**: Minimal required permissions
- **Firewall Rules**: Only necessary ports are open
- **Workload Identity**: Secure pod-to-service authentication
- **Spot Instances**: Use taints/tolerations for workload isolation
- **Master Authorized Networks**: Only configured IPs can access the control plane

## Cost Optimization

- **Spot Instances**: Up to 60% cost savings for worker pool
- **Autoscaling**: Scale down to zero for worker pool
- **Efficient Machine Types**: e2-standard-2 for apps, c4-standard-2 for compute
- **Preemptible Option**: Available for additional cost savings

## Support

For issues or questions:
1. Check the [GKE Environment Module README](../modules/gke-environment/README.md)
2. Review Terraform logs: `terraform logs`
3. Check GCP Console for cluster status
4. Verify service account permissions
5. Ensure your IP is in the master authorized networks
