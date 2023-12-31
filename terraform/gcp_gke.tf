# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
resource "google_container_cluster" "gke" {
  name                      = "cluster-${var.humanitec_env_type}"
  location                  = var.gcp_gke_autopilot ? var.gcp_region : var.gcp_zone
  remove_default_node_pool  = var.gcp_gke_autopilot ? null : true
  initial_node_count        = var.gcp_gke_autopilot ? null : 1
  datapath_provider         = "ADVANCED_DATAPATH" # Dataplane V2 (NetworkPolicies) is enabled.
  network                   = google_compute_network.vpc.id
  subnetwork                = google_compute_subnetwork.subnetwork.id
  enable_autopilot          = var.gcp_gke_autopilot

  dynamic "addons_config" {
    for_each = var.gcp_gke_autopilot ? [] : [1]
    content {
      dns_cache_config {
        enabled = true
      }
    }
  }

  cluster_autoscaling {
    enabled         = var.gcp_gke_autopilot ? null : true
    
    auto_provisioning_defaults {
      service_account = google_service_account.gke_nodes.email
      oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

      shielded_instance_config {
        enable_secure_boot          = true
        enable_integrity_monitoring = true
      }
    }
  }

  release_channel {
    channel = var.gcp_gke_release_channel
  }

  ip_allocation_policy {
    # Adding this block enables IP aliasing, making the cluster VPC-native instead of routes-based.
    cluster_secondary_range_name  = local.pods_range_name
    services_secondary_range_name = local.services_range_name
  }

  master_authorized_networks_config {
    gcp_public_cidrs_access_enabled = false

    dynamic "cidr_blocks" {
      for_each = data.humanitec_source_ip_ranges.main.cidr_blocks
      content {
        cidr_block = cidr_blocks.key
      }
    }
    cidr_blocks {
      cidr_block = "${chomp(data.http.icanhazip.response_body)}/32"
    }
  }

  node_config {
    machine_type    = var.gcp_gke_node_size
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    
    gcfs_config {
      enabled = true
    }
    
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  dynamic "confidential_nodes" {
    for_each = var.gcp_gke_autopilot ? [] : [1]
    content {
      enabled = true
    }
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
        enabled = var.gcp_gke_autopilot ? true : false
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  dynamic "workload_identity_config" {
    for_each = var.gcp_gke_autopilot ? [] : [1]
    content {
      workload_pool = "${var.gcp_project_id}.svc.id.goog"
    }
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.gcp_gke_master_ipv4_cidr_block
  }

  security_posture_config {
    mode = "BASIC"
    vulnerability_mode = "VULNERABILITY_BASIC"
  }

  lifecycle {
    ignore_changes = [
      node_config # otherwise destroy/recreate with Autopilot...
    ]
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool
resource "google_container_node_pool" "gke_node_pool" {
  count       = var.gcp_gke_autopilot ? 0 : 1
  name        = "primary"
  cluster     = google_container_cluster.gke.id
  
  autoscaling {
    min_node_count = 0
    max_node_count = 4
  }

  node_config {
    machine_type    = var.gcp_gke_node_size
    service_account = google_service_account.gke_nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}