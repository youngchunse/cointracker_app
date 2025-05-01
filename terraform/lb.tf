resource "google_compute_backend_service" "default" {
  name        = "hello-world-backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10
  health_checks = [google_compute_health_check.default.id]
  backend {
    group = google_compute_region_instance_group_manager.mig.instance_group
  }
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
