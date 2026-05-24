resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id
}

resource "google_firebase_android_app" "default" {
  provider     = google-beta
  project      = var.project_id
  display_name = "Room Booker Android"
  package_name = "org.goforthtech.roombooker"
  
  # Wait for the project to be initialized with Firebase
  depends_on = [google_firebase_project.default]
}

resource "google_firebase_web_app" "default" {
  provider     = google-beta
  project      = var.project_id
  display_name = "Room Booker Web"
  
  depends_on = [google_firebase_project.default]
}
