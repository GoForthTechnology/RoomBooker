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

resource "google_project_iam_member" "play_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.google_play.email}"
}

resource "google_project_iam_member" "play_firebase_admin" {
  project = var.project_id
  role    = "roles/firebaseappdistro.admin"
  member  = "serviceAccount:${google_service_account.google_play.email}"
}

resource "google_project_iam_member" "play_hosting_admin" {
  project = var.project_id
  role    = "roles/firebasehosting.admin"
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

resource "google_service_account" "meet_provisioner" {
  account_id   = "meet-provisioner"
  display_name = "Meet Provisioner"
}

resource "google_service_account_key" "meet_provisioner" {
  service_account_id = google_service_account.meet_provisioner.name
}

resource "google_secret_manager_secret" "meet_provisioner_key" {
  secret_id = "meet-provisioner-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "meet_provisioner_key" {
  secret      = google_secret_manager_secret.meet_provisioner_key.id
  secret_data = base64decode(google_service_account_key.meet_provisioner.private_key)
}

# Grant Cloud Functions runtime access to read the secret
resource "google_secret_manager_secret_iam_member" "functions_meet_key_access" {
  secret_id = google_secret_manager_secret.meet_provisioner_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.project_id}@appspot.gserviceaccount.com"
}

output "meet_provisioner_key" {
  value     = google_service_account_key.meet_provisioner.private_key
  sensitive = true
}
