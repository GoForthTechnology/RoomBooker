terraform {
  backend "gcs" {
    bucket = "roombooker-5e947-terraform-state"
    prefix = "terraform/state"
  }
}
