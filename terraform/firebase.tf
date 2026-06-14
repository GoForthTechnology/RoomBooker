resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id
}

resource "google_firebase_android_app" "default" {
  provider     = google-beta
  project      = var.project_id
  display_name = "Room Booker Android"
  package_name = "org.goforthtech.roombooker"
  
  sha1_hashes = [
    "B55651243831886E884954C785A966581F913D10", # Upload Key
    "15806BC9600BC6163DABD41F2D5E3A74272224F3"  # Google Play App Signing Key (Production)
  ]
  
  sha256_hashes = [
    "9750D52191471C26CF8EE7C89D8C209B20D8E435C0F87902DB7D87E998C30092", # Upload Key
    "1B6199A26DEEE1BFEEF82B57A54BCFC6FA4E66C200FB9166B51EFAA573085480"  # Google Play App Signing Key (Production)
  ]

  # Wait for the project to be initialized with Firebase
  depends_on = [google_firebase_project.default]
}

resource "google_firebase_android_app" "kiosk" {
  provider     = google-beta
  project      = var.project_id
  display_name = "Room Booker Kiosk"
  package_name = "org.goforthtech.roombooker_kiosk"
  
  # TODO: Add Kiosk signing hashes when available
  sha1_hashes = []
  sha256_hashes = []

  depends_on = [google_firebase_project.default]
}

resource "google_firebase_web_app" "default" {
  provider     = google-beta
  project      = var.project_id
  display_name = "Room Booker Web"
  
  depends_on = [google_firebase_project.default]
}
