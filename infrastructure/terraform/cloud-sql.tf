resource "random_id" "database_id" {
  byte_length = 16
}

resource "google_sql_database_instance" "master" {
  provider = google-beta

  # Google Cloud persists the database for several weeks
  # after the instance is destroyed.  By using a random_id
  # in the instance name, the name will not conflict with
  # previous runs name
  name             = "metropolis-quickstart-${random_id.database_id.hex}"
  database_version = "POSTGRES_11"
  region           = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      # Allow direct connections within the VPC in the private netowrk supplied
      ipv4_enabled    = true
      private_network = google_compute_network.private.self_link
    }

  }
}

resource "google_sql_user" "users" {
  name     = "metropolis"
  instance = google_sql_database_instance.master.name
  password = var.sql_user_password
}
