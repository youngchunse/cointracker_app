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

###### Compute ######
resource "google_compute_instance_template" "default" {
  name_prefix  = "docker-template"
  machine_type = "e2-micro"
  tags         = ["http-server"]
  region       = var.region
  metadata_startup_script = file("${path.module}/../app/startup.sh")

  disk {
    auto_delete  = true
    boot         = true
    source_image = "debian-cloud/debian-11"
    }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }
}

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
    initial_delay_sec = 60
  }
}

resource "google_compute_health_check" "default" {
  name = "http-health-check"

  http_health_check {
    port = 80
  }

  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

###### LB ######
resource "google_compute_backend_service" "default" {
  name        = "hello-world-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  health_checks = [google_compute_health_check.default.id]
  backend {
    group = google_compute_region_instance_group_manager.igm.instance_group
  }
  depends_on = [google_compute_health_check.default]
}

resource "google_compute_url_map" "default" {
  name            = "hello-world-url-map"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_http_proxy" "default" {
  name   = "hello-world-http-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "hello-world-forwarding-rule"
  port_range = "80"
  target     = google_compute_target_http_proxy.default.id
}

###### Network ######
resource "google_compute_network" "vpc" {
  name = "hello-world-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "hello-world-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

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
