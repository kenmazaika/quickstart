data "google_secret_manager_secret_version" "metropolis_quickstart_database_password" {
  provider = google-beta

  secret  = "metropolis-quickstart-database-password"
  version = "1"
}


data "google_secret_manager_secret_version" "metropolis_rails_master_key" {
  provider = google-beta

  secret = "metropolis-quickstart-rails-master-key"
}


resource "kubernetes_secret" "metropolis_quickstart_database_credentials" {
  metadata {
    name = "metropolis-quickstart-database-credentials"
  }

  data = {
    username      = "metropolis"
    password      = data.google_secret_manager_secret_version.metropolis_quickstart_database_password.secret_data
    host          = google_sql_database_instance.master.ip_address[index(google_sql_database_instance.master.ip_address.*.type, "PRIVATE")].ip_address
    database_name = google_sql_database_instance.master.name
  }
}

resource "kubernetes_secret" "metropolis_rails_master_key" {
  metadata {
    name = "metropolis-quickstart-rails-master-key"
  }

  data = {
    value = data.google_secret_manager_secret_version.metropolis_rails_master_key.secret_data
  }
}



resource "google_secret_manager_secret" "secret-basic" {
  provider = google-beta

  secret_id = "metropolis-quickstart-gcp-service-account"


  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "metropolis_gcp_service_account" {
  provider = google-beta

  secret = google_secret_manager_secret.secret-basic.id
  secret_data = file(var.credentials_file)
}