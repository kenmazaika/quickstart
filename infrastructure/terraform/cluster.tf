resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 2

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # Enable VPC-Native
  # Required for CloudSQL connection
  ip_allocation_policy {
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
  network    = google_compute_network.private.self_link
}


resource "google_container_node_pool" "primary" {
  name       = "metropolis-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1" # zones/us-central1-f/machineTypes/custom-4-5120

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "kubernetes_secret" "gcr_docker_configuration" {
  metadata {
    name = "gcr-docker-configuration"
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      "auths" : {
        "gcr.io" : {
          email    = var.gcr_email
          username = "_json_key"
          password = file(var.credentials_file)
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}