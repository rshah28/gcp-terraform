# GKE Autopilot Environment

This directory contains Terraform configuration for deploying a **Google Kubernetes Engine (GKE) Autopilot** cluster. GKE Autopilot is a fully managed Kubernetes service that automatically handles node management, scaling, and security configurations.

## Overview

GKE Autopilot provides:
- **Fully managed nodes**: Google automatically manages node provisioning, scaling, and updates
- **Enhanced security**: Built-in security features with minimal configuration
- **Cost optimization**: Pay only for the resources your workloads consume
- **Simplified operations**: No need to manage node pools, autoscaling, or infrastructure

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GKE Autopilot Cluster                    │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Control Plane │  │  Auto-managed   │  │   Workload   │ │
│  │   (Google       │  │     Nodes       │  │   Identity   │ │
│  │   Managed)      │  │                 │  │              │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    VPC Network                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   GKE Subnet    │  │   Pods Range    │  │ Services     │ │
│  │                 │  │                 │  │ Range        │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

Before deploying this environment, ensure you have completed the prerequisites outlined in the [main README](../README.md#prerequisites).

## Deployment

### 1. Configure Environment

Review and customize the variables in `variables.tf` or create a `terraform.tfvars` file:

```hcl
# terraform.tfvars
env_name = "production-autopilot"
gcp_project_id = "your-project-id"
gcp_region = "us-central1"

# Optional: Configure master authorized networks for secure access
master_authorized_cidr_blocks = [
  {
    display_name = "Office Network"
    cidr_block   = "203.0.113.0/24"
  }
]
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

### 3. Configure kubectl

After deployment, configure kubectl to access your cluster:

```bash
# Get the command from outputs
terraform output kubectl_config_command

# Or run directly
gcloud container clusters get-credentials gke-autopilot-env-cluster \
  --region us-central1 \
  --project your-project-id
```

## Configuration

### Required Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `env_name` | Environment name | `"gke-autopilot-env"` |
| `gcp_project_id` | GCP Project ID | `"<YOUR_PROJECT_ID>"` |
| `gcp_region` | GCP Region | `"us-central1"` |

### Network Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `gke_subnet_cidr_range` | GKE subnet CIDR | `"10.0.0.0/20"` |
| `gke_pods_subnet_cidr_range` | Pods secondary range | `"10.12.0.0/14"` |
| `gke_services_subnet_cidr_range` | Services secondary range | `"10.16.0.0/14"` |
| `cluster_master_cidr_block` | Master authorized network | `"10.20.0.0/28"` |

### Security Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `master_authorized_cidr_blocks` | Authorized CIDR blocks | `[]` |
| `gke_maintenance_start_time` | Maintenance window | `"05:00"` |

## Usage Examples

### Deploy Applications

```bash
# Deploy a sample application
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
EOF
```

### Use Workload Identity

```yaml
# Example: Access Google Cloud Storage with Workload Identity
apiVersion: v1
kind: ServiceAccount
metadata:
  name: gcs-access-sa
  annotations:
    iam.gke.io/gcp-service-account: gcs-access@your-project-id.iam.gserviceaccount.com
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gcs-app
spec:
  template:
    spec:
      serviceAccountName: gcs-access-sa
      containers:
      - name: app
        image: gcr.io/google.com/cloudsdktool/cloud-sdk
        command: ["gsutil", "ls", "gs://your-bucket"]
```

### Monitor Cluster

```bash
# View cluster nodes (Autopilot manages these automatically)
kubectl get nodes

# View cluster events
kubectl get events --sort-by='.lastTimestamp'

# Check cluster autoscaling status
kubectl describe clusterautoscaler

# View logs in Google Cloud Console
gcloud logging read "resource.type=gke_cluster AND resource.labels.cluster_name=gke-autopilot-env-cluster" --limit=50
```

## Key Features

### Automatic Node Management
- **Node provisioning**: Automatically creates nodes when pods are pending
- **Node scaling**: Scales nodes up and down based on workload demands
- **Node updates**: Automatically updates nodes with security patches
- **Node repair**: Automatically replaces unhealthy nodes

### Security Features
- **Workload Identity**: Secure pod-to-service authentication
- **Private cluster**: Control plane and nodes are private by default
- **Shielded nodes**: Secure boot and integrity monitoring enabled
- **Node auto-upgrades**: Automatic security updates
- **VPC-native**: Uses VPC for pod and service networking

### Cost Optimization
- **Pay-per-use**: Only pay for resources consumed by your workloads
- **Automatic scaling**: Nodes are created and destroyed as needed
- **No idle costs**: No charges for unused node capacity

## Maintenance

### Cluster Updates
GKE Autopilot automatically handles:
- **Control plane updates**: Managed by Google
- **Node updates**: Automatic with zero downtime
- **Security patches**: Applied automatically

### Monitoring
```bash
# Check cluster health
gcloud container clusters describe gke-autopilot-env-cluster --region us-central1

# View cluster metrics
gcloud monitoring metrics list --filter="metric.type:kubernetes.io"

# Monitor costs
gcloud billing accounts list
```

## Troubleshooting

### Common Issues

**Cluster Access Denied**
```bash
# Ensure you have proper IAM permissions
gcloud projects get-iam-policy your-project-id

# Check if master authorized networks are configured
gcloud container clusters describe gke-autopilot-env-cluster --region us-central1
```

**Pod Scheduling Issues**
```bash
# Check pod events
kubectl describe pod <pod-name>

# Check node resources
kubectl describe nodes

# Check autoscaler status
kubectl describe clusterautoscaler
```

**Network Connectivity**
```bash
# Test pod-to-pod connectivity
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup kubernetes.default

# Check VPC firewall rules
gcloud compute firewall-rules list --filter="network=gke-autopilot-env-vpc"
```

## Useful Commands

```bash
# Get cluster information
terraform output

# View cluster in Google Cloud Console
terraform output cluster_dashboard_url

# Configure kubectl
eval $(terraform output kubectl_config_command)

# View cluster logs
gcloud logging read "resource.type=gke_cluster AND resource.labels.cluster_name=$(terraform output -raw cluster_name)" --limit=100

# Check cluster costs
gcloud billing accounts list
```

## Security Considerations

- **Private cluster**: Control plane and nodes are private by default
- **Master authorized networks**: Configure specific CIDR blocks for cluster access
- **Workload Identity**: Use IAM roles instead of service account keys
- **VPC-native**: Leverages VPC for enhanced network security
- **Automatic updates**: Security patches are applied automatically

## Cost Optimization

- **Right-sizing**: Autopilot automatically sizes nodes based on workload requirements
- **No idle costs**: Nodes are only created when needed
- **Automatic scaling**: Scales to zero when workloads are not running
- **Resource quotas**: Set resource limits to control costs

## Support

For issues related to:
- **Terraform configuration**: Check the [main README](../README.md)
- **GKE Autopilot**: Refer to [GKE Autopilot documentation](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview)
- **Google Cloud**: Contact [Google Cloud Support](https://cloud.google.com/support) 