# GCP Terraform Infrastructure

This repository contains Terraform configurations for Google Cloud Platform (GCP) infrastructure, including Google Kubernetes Engine (GKE) environments with comprehensive networking, security, and infrastructure components.

## Prerequisites

### Assumptions
- ✅ GCP Project is already created and billing is enabled
- ✅ Organization-level resources are already configured
- ✅ User has appropriate permissions to create and manage resources

### Required Tools
- **Terraform**: Version >= 1.5.7
- **Google Cloud SDK**: Latest version
- **kubectl**: For Kubernetes cluster management (optional but recommended)

## Configuration Setup

### Important: Replace Placeholders

Before deploying, you must replace the following placeholders with your actual values:

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `<YOUR_PROJECT_ID>` | Your GCP Project ID | `my-awesome-project-123` |
| `<YOUR_CLOUD_SHELL_IP>` | Your Cloud Shell IP for cluster access | `203.0.113.1` |

**Quick Setup (Recommended):**
```bash
# Run the setup script to automatically replace placeholders
./setup-project.sh my-awesome-project-123
```

**Manual Setup:**
Files that need updating:
- `gke-standard/main.tf` - Backend bucket and service account
- `gke-autopilot/main.tf` - Backend bucket and service account  
- `gke-standard/variables.tf` - Default project ID
- `gke-autopilot/variables.tf` - Default project ID

**Example:**
```hcl
# Before
bucket = "<YOUR_PROJECT_ID>-tf-state"
impersonate_service_account = "terraform@<YOUR_PROJECT_ID>.iam.gserviceaccount.com"

# After
bucket = "my-awesome-project-123-tf-state"
impersonate_service_account = "terraform@my-awesome-project-123.iam.gserviceaccount.com"
```

### Required Tools

### GCP Setup Requirements

Before deploying any environment, you must complete the GCP setup requirements:

#### 1. Create Terraform Service Account

```bash
# Set your project ID
export PROJECT_ID="your-project-id"

# Create the service account
gcloud iam service-accounts create terraform \
  --display-name="Terraform Service Account" \
  --description="Service account for Terraform infrastructure management" \
  --project=$PROJECT_ID

# Get the service account email
export SA_EMAIL="terraform@${PROJECT_ID}.iam.gserviceaccount.com"
```

#### 2. Allow User Account to Impersonate Terraform SA

```bash
# Get your user account email
export USER_EMAIL=$(gcloud config get-value account)

# Grant impersonation permission
gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL \
  --member="user:${USER_EMAIL}" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --project=$PROJECT_ID
```

#### 3. Create GCS Bucket for Terraform State

```bash
# Set unique bucket name (must be globally unique)
export BUCKET_NAME="your-project-terraform-state"

# Create the bucket
gsutil mb -p $PROJECT_ID -c STANDARD -l us-central1 gs://$BUCKET_NAME

# Enable versioning for state files
gsutil versioning set on gs://$BUCKET_NAME
```

#### 4. Assign Required IAM Roles

```bash
# Add Editor role for general resource management
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/editor"

# Add Viewer role for reading project information
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/viewer"

# Add IAM Admin role for managing service accounts and roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountAdmin"

# Add Service Account User role for impersonation
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountUser"

# Add Storage Admin role for managing GCS buckets
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin"

# Add Compute Admin role for managing compute resources
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/compute.admin"

# Add Container Admin role for managing GKE clusters
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/container.admin"

# Add Service Usage Admin role for enabling APIs
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/serviceusage.serviceUsageAdmin"
```

#### 5. Enable Required APIs

```bash
# Enable required APIs
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  compute.googleapis.com \
  container.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  serviceusage.googleapis.com \
  storage.googleapis.com \
  --project=$PROJECT_ID
```

#### 6. Configure Authentication

```bash
# Set environment variable for service account impersonation
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="terraform@your-project-id.iam.gserviceaccount.com"

# Or configure in your shell profile (~/.bashrc, ~/.zshrc, etc.)
echo 'export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="terraform@your-project-id.iam.gserviceaccount.com"' >> ~/.bashrc
source ~/.bashrc
```

#### 7. Configure Master Authorized Networks

To access the Kubernetes cluster, configure your IP address:

```bash
# Get your public IP address
export YOUR_IP=$(curl -s ifconfig.me)

# Add your IP to the authorized networks in the environment-specific configuration
```

## Available Environments

This repository contains Terraform configurations for different GKE deployment patterns:

### GKE Standard Environment

A GKE Standard cluster featuring:
- **Multi-node pool architecture** with spot instances for cost optimization
- **Private networking** with VPC-native cluster
- **Modular firewall rules** for security
- **Workload Identity** for secure authentication
- **Master authorized networks** for secure cluster access

For detailed instructions, see [gke-standard/README.md](gke-standard/README.md).

### GKE Autopilot Environment

A fully managed GKE Autopilot cluster featuring:
- **Fully managed nodes** with automatic provisioning and scaling
- **Enhanced security** with built-in security features
- **Cost optimization** with pay-per-use pricing
- **Simplified operations** with no node management required
- **Workload Identity** for secure authentication

For detailed instructions, see [gke-autopilot/README.md](gke-autopilot/README.md).

## Security Best Practices

- ✅ Use service account impersonation instead of keys
- ✅ Use remote state storage (GCS) with versioning
- ✅ Use private GKE clusters with authorized networks
- ✅ Configure firewall rules minimally
- ✅ Enable Workload Identity for secure authentication

## Useful Commands

```bash
# Check Terraform version
terraform version

# Validate configuration
terraform validate

# Format configuration files
terraform fmt

# Check provider configuration
terraform providers
```

## Getting Help

1. Check the [GKE Environment Module README](modules/gke-environment/README.md)
2. Review environment-specific READMEs (e.g., [GKE Standard](gke-standard/README.md))
3. Check Terraform documentation: https://www.terraform.io/docs
4. Review Google Cloud documentation: https://cloud.google.com/docs

## Contributing

When contributing to this repository:

1. **Follow Terraform best practices**
2. **Update documentation** for any changes
3. **Test configurations** before submitting
4. **Use consistent formatting** (`terraform fmt`)
5. **Validate configurations** (`terraform validate`)

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

## Repository Structure

```
gcp-terraform/
├── modules/
│   └── gke-environment/          # Reusable GKE environment module
│       ├── main.tf              # Provider configuration and project services
│       ├── variables.tf         # Input variables
│       ├── outputs.tf           # Output values
│       ├── gke.tf              # GKE cluster and node pool resources
│       ├── vpc.tf              # VPC, subnet, router, and NAT resources
│       ├── service_accounts.tf  # Service account and IAM resources
│       ├── firewall.tf         # Firewall rules
│       └── README.md           # Module documentation
├── gke-standard/                # GKE Standard environment implementation
│   ├── main.tf                 # Main configuration using gke-environment module
│   ├── variables.tf            # Environment-specific variables
│   ├── outputs.tf              # Environment outputs
│   └── README.md              # Environment-specific documentation
├── gke-autopilot/              # GKE Autopilot environment implementation
│   ├── main.tf                 # Main configuration using gke-environment module
│   ├── variables.tf            # Environment-specific variables
│   ├── outputs.tf              # Environment outputs
│   └── README.md              # Environment-specific documentation
├── setup-project.sh            # Script to replace project placeholders
├── .gitignore                  # Git ignore rules
├── LICENSE                     # License file
└── README.md                   # This file
```

## Quick Start

### 1. Complete Prerequisites

Ensure you have completed all prerequisites listed above.

### 2. Choose Environment

Navigate to the desired environment directory:

```bash
cd gke-standard    # For GKE Standard with manual node management
# or
cd gke-autopilot   # For GKE Autopilot with fully managed nodes
```

### 3. Configure and Deploy

Follow the environment-specific README for detailed configuration and deployment instructions:

- **[GKE Standard Environment](gke-standard/README.md)** - GKE cluster with multi-node pools
- **[GKE Autopilot Environment](gke-autopilot/README.md)** - Fully managed GKE cluster
