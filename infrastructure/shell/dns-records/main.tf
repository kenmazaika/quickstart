provider "google" {
  version     = "3.5.0"
  credentials = "gcp-service-account.json"
  project     = "hello-metropolis"
}


data "terraform_remote_state" "terraform-state" {
  backend = "gcs"
  config = {
    bucket      = "hello-metropolis-terraform-state"
    prefix      = "metropolis-quickstart-managed-state"
    credentials = "gcp-service-account.json"
  }
}

resource "google_dns_record_set" "custom-record" {
  managed_zone = "hello-metropolis"
  name = "${var.domain}."
  type = "A"
  ttl = 300
  rrdatas = [var.ip_address]
}