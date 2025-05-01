resource "google_compute_network" "vpc" {
  name = "hello-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "hello-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow-http" {
  name    = "allow-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  direction = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
}


resource "google_compute_instance_template" "default" {
  name_prefix = "hello-template"
  region      = var.region

  tags = ["http-server"]

  disk {
    boot  = true
    auto_delete = true
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }

  metadata_startup_script = file("${path.module}/../app/startup.sh")
  machine_type = "e2-micro"
}

resource "google_compute_region_instance_group_manager" "default" {
  name               = "hello-mig"
  region             = var.region
  base_instance_name = "hello-instance"
  version {
    instance_template = google_compute_instance_template.default.self_link
  }

  target_size = 2

  auto_healing_policies {
    health_check      = google_compute_health_check.default.id
    initial_delay_sec = 30
  }
}

resource "google_compute_health_check" "default" {
  name               = "http-health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 3

  http_health_check {
    port = 80
    request_path = "/"
  }
}

resource "google_compute_backend_service" "default" {
  name          = "hello-backend"
  protocol      = "HTTP"
  port_name     = "http"
  timeout_sec   = 10
  health_checks = [google_compute_health_check.default.id]

  backend {
    group = google_compute_region_instance_group_manager.default.instance_group
  }
}

resource "google_compute_url_map" "default" {
  name            = "hello-url-map"
  default_service = google_compute_backend_service.default.self_link
}

resource "google_compute_target_http_proxy" "default" {
  name   = "hello-http-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "hello-forwarding-rule"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
}
