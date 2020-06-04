terraform {
  required_version = ">= 0.12"

  required_providers {
    google-beta = ">= 3.8"
  }
}


###############################################################################
# Variables
###############################################################################
variable "credentials_file" {}
variable "project" {}
variable "cluster_name" {}
variable "metropolis_public_key" {}
variable "metropolis_private_key" {}
variable "zone" {}
variable "region" {}
variable "sql_user_password" {}
variable "gcr_email" {}
variable "docker_repo_frontend" {}
variable "docker_repo_backend" {}
variable "github_clone_url" {}

###############################################################################
# Providers
###############################################################################

provider "google" {
  version = "3.5.0"

  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
  zone        = var.zone
}

provider "google-beta" {
  project     = var.project
  credentials = file(var.credentials_file)
}

provider "kubernetes" {
  load_config_file       = false
  host                   = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

provider "helm" {
  kubernetes {
  load_config_file       = false
  host                   = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
  }
}

provider "metropolis" {
  host        = "http://hellometropolis.com"

  public_key  = var.metropolis_public_key
  private_key = var.metropolis_private_key
}


###############################################################################
# Configuration
###############################################################################

data "terraform_remote_state" "terraform-state" {
  backend = "gcs"
  config = {
    bucket  = "metropolis-quickstart-terraform-state"
    prefix  = "sandbox"
    credentials = var.credentials_file
  }
}

data "google_client_config" "default" {
}

data "kubernetes_service" "nginx_ingress_controller" {
  metadata {
    name = "${helm_release.nginx_ingress.name}-controller"
  }

  # Wait to build the ingress before refreshing the
  # kubernetes service
  depends_on = [
    helm_release.nginx_ingress,
  ]

}

# ###############################################################################
# # Misc
# ###############################################################################
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  chart      = "stable/nginx-ingress"
}