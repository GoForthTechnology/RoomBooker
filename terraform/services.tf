resource "google_project_service" "cloudbilling" {
  project = var.project_id
  service = "cloudbilling.googleapis.com"

  disable_on_destroy = false
}
