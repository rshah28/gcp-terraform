# Firewall rule to allow GKE control plane to reach worker nodes on configurable ports
# GKE control plane allows access to only TCP connections to nodes/pods on ports 443 (HTTPS) and 10250 (kubelet) by default.
resource "google_compute_firewall" "gke_control_plane_node_access" {
  count       = (length(var.gke_control_plane_allowed_ports) > 0 && !var.autopilot) ? 1 : 0
  project     = var.gcp_project_id
  name        = "${var.env_name}-gke-control-plane-node-access"
  description = "Allow GKE control plane nodes to reach worker nodes on configurable ports (NGINX ingress controller, Datadog cluster agent, Linkerd Control Plane, etc.)"
  network     = google_compute_network.default.self_link

  source_ranges = [
    var.cluster_master_cidr_block,
  ]

  dynamic "allow" {
    for_each = var.gke_control_plane_allowed_ports
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  target_service_accounts = [
    google_service_account.gke_cluster_sa.email
  ]
}
