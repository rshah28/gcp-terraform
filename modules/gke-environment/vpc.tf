# Create a custom VPC network for the GKE environment
resource "google_compute_network" "default" {
  project                 = var.gcp_project_id
  name                    = "${var.env_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"

  depends_on = [
    google_project_service.project_service
  ]
}

# Create a subnet for GKE nodes with secondary IP ranges for pods and services
resource "google_compute_subnetwork" "gke" {
  project                  = var.gcp_project_id
  name                     = "${var.env_name}-${var.gcp_region}-gke-subnet"
  region                   = var.gcp_region
  network                  = google_compute_network.default.self_link
  private_ip_google_access = true
  ip_cidr_range            = var.gke_subnet_cidr_range

  # Enable VPC flow logs for network monitoring and security analysis
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  # This range is used for pod IP addresses in the cluster
  secondary_ip_range {
    range_name    = "${var.env_name}-gke-pods"
    ip_cidr_range = var.gke_pods_subnet_cidr_range
  }

  # This range is used for ClusterIP service addresses
  secondary_ip_range {
    range_name    = "${var.env_name}-gke-services"
    ip_cidr_range = var.gke_services_subnet_cidr_range
  }
}

# Create a Cloud Router for NAT gateway configuration
resource "google_compute_router" "nat_router" {
  name    = "${var.env_name}-${var.gcp_region}-nat-router"
  project = var.gcp_project_id
  region  = var.gcp_region
  network = google_compute_network.default.self_link
}

# Configure NAT gateway for outbound internet access
# This allows private nodes to access external services while remaining private
resource "google_compute_router_nat" "default" {
  name                               = "${var.env_name}-${var.gcp_region}-nat"
  project                            = var.gcp_project_id
  region                             = var.gcp_region
  router                             = google_compute_router.nat_router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  # This enables outbound internet access for all nodes in the GKE subnet
  subnetwork {
    name                    = google_compute_subnetwork.gke.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}