resource "google_container_cluster" "gke_autopilot_cluster" {
  count               = var.autopilot ? 1 : 0
  project             = var.gcp_project_id
  name                = var.cluster_name
  location            = var.gcp_region
  network             = google_compute_network.default.self_link
  subnetwork          = google_compute_subnetwork.gke.self_link
  deletion_protection = false # to delete the cluster after testing

  depends_on = [
    google_project_service.project_service,
    google_service_account.gke_cluster_sa
  ]

  enable_autopilot = true

  # Accept known production-ready upgrades to the kubernetes version
  release_channel {
    channel = "REGULAR"
  }

  # Disable basic authentication
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Enable Workload Identity for secure pod-to-service authentication
  # This allows pods to authenticate to GCP services using IAM without service account keys
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Make this a vpc-native cluster
  # Configure the secondary range to use for:
  # - pod IPs (cluster*)
  # - ClusterIPs (services*)
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Enable a private cluster
  # enable_private_nodes: nodes will only get internal addresses
  # enable_private_endpoint: either the public or private endpoint can be used
  # master_ipv4_cidr_block: a block used for the master network (/28 required)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.cluster_master_cidr_block
  }

  # Allow only specific CIDR blocks access to the public endpoint
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_cidr_blocks

      content {
        display_name = cidr_blocks.value.display_name
        cidr_block   = cidr_blocks.value.cidr_block
      }
    }
  }

  # Configure maintenance window for cluster updates and upgrades
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.gke_maintenance_start_time
    }
  }
}

resource "google_container_cluster" "gke_standard_cluster" {
  count               = var.autopilot ? 0 : 1
  project             = var.gcp_project_id
  name                = var.cluster_name
  location            = var.gcp_region
  network             = google_compute_network.default.self_link
  subnetwork          = google_compute_subnetwork.gke.self_link
  deletion_protection = false # to delete the cluster after testing

  depends_on = [
    google_project_service.project_service,
    google_service_account.gke_cluster_sa
  ]

  # This allows the cluster to scale up when pods are pending and scale down when nodes are underutilized
  cluster_autoscaling {
    enabled = var.cluster_autoscaling

    # Defines the minimum and maximum CPU cores that can be allocated across all nodes
    dynamic "resource_limits" {
      for_each = var.cluster_autoscaling ? [1] : []
      content {
        resource_type = "cpu"
        minimum       = var.nap_min_cpu
        maximum       = var.nap_max_cpu
      }
    }

    # Defines the minimum and maximum memory in GB that can be allocated across all nodes
    dynamic "resource_limits" {
      for_each = var.cluster_autoscaling ? [1] : []
      content {
        resource_type = "memory"
        minimum       = var.nap_min_memory
        maximum       = var.nap_max_memory
      }
    }

    # Configure default settings for auto-provisioned nodes
    # This defines how new nodes are created when cluster autoscaling is triggered
    dynamic "auto_provisioning_defaults" {
      for_each = var.cluster_autoscaling ? [1] : []
      content {
        oauth_scopes = [
          "https://www.googleapis.com/auth/cloud-platform",
        ]
        service_account = google_service_account.gke_cluster_sa.email
        image_type      = "COS_CONTAINERD"

        # allow automatic repair and upgrade of node pools
        management {
          auto_repair  = true
          auto_upgrade = true
        }

        # Configure node pool upgrade strategy
        # Two strategies are supported:
        # - "surge": Creates additional nodes during upgrades (faster, more resources)
        # - "blue-green": Creates new node pool and migrates workloads (safer, zero downtime)
        dynamic "upgrade_settings" {
          for_each = var.upgrade_strategy == "blue-green" ? [1] : []
          content {
            strategy = "BLUE_GREEN"
            blue_green_settings {
              standard_rollout_policy {
                batch_percentage = var.blue_green_batch_percentage
              }
            }
          }
        }

        dynamic "upgrade_settings" {
          for_each = var.upgrade_strategy == "surge" ? [1] : []
          content {
            strategy        = "SURGE"
            max_surge       = var.nap_max_surge
            max_unavailable = var.nap_surge_max_unavailable
          }
        }

        # Enable Shielded Instance features (Secure Boot + Integrity Monitoring) for enhanced security
        shielded_instance_config {
          enable_secure_boot          = true
          enable_integrity_monitoring = true
        }
      }
    }
  }

  # Initial_node_count is required when the default node pool is removed
  initial_node_count       = 1
  remove_default_node_pool = true

  # Accept known production-ready upgrades to the kubernetes version
  release_channel {
    channel = "REGULAR"
  }

  # Disable basic authentication
  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Enable Workload Identity for secure pod-to-service authentication
  # This allows pods to authenticate to GCP services using IAM without service account keys
  workload_identity_config {
    workload_pool = "${var.gcp_project_id}.svc.id.goog"
  }

  # Make this a vpc-native cluster
  # Configure the secondary range to use for:
  # - pod IPs (cluster*)
  # - ClusterIPs (services*)
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Enable a private cluster
  # enable_private_nodes: nodes will only get internal addresses
  # nable_private_endpoint: either the public or private endpoint can be used
  # master_ipv4_cidr_block: a block used for the master network (/28 required)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.cluster_master_cidr_block
  }

  # Allow only specific CIDR blocks access to the public endpoint
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_cidr_blocks

      content {
        display_name = cidr_blocks.value.display_name
        cidr_block   = cidr_blocks.value.cidr_block
      }
    }
  }

  # Use Dataplane V2 which has more performant eBPF-based networking
  datapath_provider = "ADVANCED_DATAPATH"

  # Configure maintenance window for cluster updates and upgrades
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.gke_maintenance_start_time
    }
  }
}

resource "google_container_node_pool" "node_pool" {
  # We only need to create node pools if autopilot is disabled
  for_each = var.autopilot == false ? var.node_pools : {}

  name     = each.key
  project  = var.gcp_project_id
  location = var.gcp_region
  cluster  = google_container_cluster.gke_standard_cluster[0].name

  # Start with the minimum node count, but enable autoscaling
  initial_node_count = each.value.min_node_count
  autoscaling {
    total_min_node_count = each.value.min_node_count
    total_max_node_count = each.value.max_node_count
  }

  lifecycle {
    ignore_changes = [
      # Changing initial_node_count triggers a delete/create of the node pool
      initial_node_count,
      # Ignore changes to these automatically added config and labels
      node_config.0.kubelet_config,
      node_config.0.resource_labels
    ]
  }

  # Allow automatic repair and upgrade of node pools
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Configure each compute instance (node) in the pool
  node_config {
    machine_type    = each.value.machine_type
    labels          = each.value.labels
    image_type      = "COS_CONTAINERD"
    tags            = var.node_tags
    service_account = google_service_account.gke_cluster_sa.email
    # Enable preemptible instances for cost optimization (can be terminated by Google)
    preemptible = lookup(each.value, "preemptible", false)
    # Enable spot instances for maximum cost savings (can be terminated at any time)
    spot = lookup(each.value, "spot", false)
    # Grant full cloud platform access to the nodes for GCP service integration
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    # Disable legacy metadata endpoints for enhanced security
    metadata = {
      disable-legacy-endpoints = "true"
    }
    # Apply taints to the node pool if specified
    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }
}
