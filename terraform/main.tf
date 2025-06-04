# ----------------------------------------
# Provider Configuration
# ----------------------------------------
provider "google" {
  project = var.project_id
  region  = var.region
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ----------------------------------------
# IAM and Service Account
# ----------------------------------------

# Creates a custom service account for the VM instances
resource "google_service_account" "custom_service_account" {
  account_id   = "custom-vm-sa"
  display_name = "Custom VM Service Account"
}

# Creates a custom service account for the instances
resource "google_project_iam_member" "custom_service_account_role" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.custom_service_account.email}"
}

# Allow pulling images from GCR
resource "google_project_iam_member" "gcr_pull" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.custom_service_account.email}"
}

# Required for interacting with Container Registry or Artifact Registry
resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.custom_service_account.email}"
}

# ----------------------------------------
# Compute Engine - Instance Template
# ----------------------------------------

# Defines the instance template for VMs in the group
resource "google_compute_instance_template" "default" {
  name_prefix  = "docker-template"
  machine_type = "e2-micro"
  tags         = ["http-server", "ssh-access"]
  region       = var.region

  # Enables OS Login for IAM-based SSH access
  metadata     = { enable-oslogin = "TRUE" }

  # Runs this startup script on instance boot
  metadata_startup_script = file("${path.module}/../app/startup.sh")

  # Root disk configuration
  disk {
    auto_delete  = true
    boot         = true
    source_image = "debian-cloud/debian-11"
    }

  # Network interface with access config for public IP
  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }

  # Attach a custom service account with necessary permissions
  service_account {
    email  = google_service_account.custom_service_account.email
    scopes = ["cloud-platform"]
  }
}

# ----------------------------------------
# Managed Instance Group
# ----------------------------------------

# Creates a regional managed instance group from the template
resource "google_compute_region_instance_group_manager" "igm" {
  name               = "hello-world-igm"
  base_instance_name = "hello-world"
  region             = var.region
  version {
    instance_template = google_compute_instance_template.default.id
  }

  target_size = 2
  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 360
  }
  named_port {
    name = "http"
    port = 80
  }
}

# ----------------------------------------
# Health Check
# ----------------------------------------

# HTTP health check for load balancer and MIG
resource "google_compute_health_check" "default" {
  name = "http-health-check"

  http_health_check {
    port = 80
    request_path = "/"
  }

  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

# ----------------------------------------
# Load Balancer Configuration
# ----------------------------------------

# Backend service for the load balancer
resource "google_compute_backend_service" "default" {
  name        = "hello-world-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  health_checks = [google_compute_health_check.default.id]
  backend {
    group = google_compute_region_instance_group_manager.igm.instance_group
  }
  depends_on = [
    google_compute_health_check.default,
    google_compute_region_instance_group_manager.igm
  ]
}

# URL map to route requests to the backend service
resource "google_compute_url_map" "default" {
  name            = "hello-world-url-map"
  default_service = google_compute_backend_service.default.id
}

# HTTP proxy that uses the URL map
resource "google_compute_target_http_proxy" "default" {
  name   = "hello-world-http-proxy"
  url_map = google_compute_url_map.default.id
}

# Global IP address for the load balancer
resource "google_compute_global_address" "default" {
  name = "hello-world-lb-ip"
}

# Global forwarding rule to route incoming traffic to the proxy
resource "google_compute_global_forwarding_rule" "default" {
  name       = "hello-world-forwarding-rule"
  port_range = "80"
  target     = google_compute_target_http_proxy.default.id
  ip_address = google_compute_global_address.default.address

}

# ----------------------------------------
# Networking (VPC, Subnet, Firewall)
# ----------------------------------------

# Creates a custom VPC network
resource "google_compute_network" "vpc" {
  name = "hello-world-vpc"
  auto_create_subnetworks = false
}

# Subnet within the custom VPC
resource "google_compute_subnetwork" "subnet" {
  name          = "hello-world-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Firewall rule to allow HTTP traffic to instances
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["http-server"]
}

# Firewall rule to allow SSH only from a specific IP
resource "google_compute_firewall" "allow_ssh_from_your_ip" {
  name    = "allow-ssh-from-your-ip"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["47.156.161.48/32"]

  target_tags = ["ssh-access"]
}