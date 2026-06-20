resource "google_project_service" "cloudbilling" {
  project = var.project_id
  service = "cloudbilling.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "meet" {
  project = var.project_id
  service = "meet.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"

  disable_on_destroy = false
}
