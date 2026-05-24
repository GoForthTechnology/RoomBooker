resource "google_service_account" "github_actions" {
  account_id   = "github-actions-deployer"
  display_name = "GitHub Actions Deployer"
}

resource "google_project_iam_member" "firebase_admin" {
  project = var.project_id
  role    = "roles/firebase.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "firebase_app_distro_admin" {
  project = var.project_id
  role    = "roles/firebaseappdistro.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "service_usage_consumer" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Note: The service account key should be generated and added to GitHub Secrets.
resource "google_service_account_key" "github_actions" {
  service_account_id = google_service_account.github_actions.name
}

output "service_account_key" {
  value     = google_service_account_key.github_actions.private_key
  sensitive = true
}

resource "google_service_account" "google_play" {
  account_id   = "google-play-deployer"
  display_name = "Google Play Deployer"
}

resource "google_project_iam_member" "play_service_usage_consumer" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.google_play.email}"
}

resource "google_service_account_key" "google_play" {
  service_account_id = google_service_account.google_play.name
}

output "google_play_service_account_key" {
  value     = google_service_account_key.google_play.private_key
  sensitive = true
}

output "google_play_service_account_email" {
  value = google_service_account.google_play.email
}
