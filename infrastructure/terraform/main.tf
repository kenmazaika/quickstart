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


###############################################################################
# Modules
###############################################################################
# module "cloud-sql" {
#   source = "../../modules/cloud-sql"

#   region               = var.region
#   zone                 = var.zone
#   sql_user_password    = module.secrets.database_password
#   database_name_prefix = "production"
  
#   private_network         = module.vpc.private_network.self_link
#   private_vpc_connection  = module.vpc.private_vpc_connection
# }


# module "vpc" {
#   source = "../../modules/vpc"

#   network_name = "private-network"
# }


# module "cluster" {
#   source = "../../modules/cluster"

#   region            = var.region
#   cluster_name      = var.cluster_name
#   credentials_file  = var.credentials_file

#   private_vpc_connection = module.vpc.private_vpc_connection
#   private_network        = module.vpc.private_network
# }

# module "redis" {
#   source = "../../modules/redis"

#   private_network        = module.vpc.private_network
#   private_vpc_connection = module.vpc.private_vpc_connection
#   instance_name_prefix   = "prod"
# }

# module "deployment" {
#   source = "../../modules/deployment"
#   name                   = "Production"
#   environment            = "production"
  
#   database_private_ip    = module.cloud-sql.host
#   database_name          = module.cloud-sql.database_name
#   cluster_name           = var.cluster_name
#   database_instance_name = "${var.project}:${var.region}:${module.cloud-sql.database_name}"
#   ingress_ip_address     = data.kubernetes_service.nginx_ingress_controller.load_balancer_ingress.0.ip
#   redis_host             = module.redis.host
# }

# module "secrets" {
#   source = "../../modules/secrets"

#   database_host = module.cloud-sql.host
#   database_name = module.cloud-sql.database_name
#   environment   = "production"
# }

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

# provider "kubernetes" {
#   load_config_file       = false
#   host                   = "https://${module.cluster.container_cluster.endpoint}"
#   cluster_ca_certificate = base64decode(module.cluster.container_cluster.master_auth.0.cluster_ca_certificate)
#   token                  = data.google_client_config.default.access_token
# }

# provider "helm" {
#   kubernetes {
#   load_config_file       = false
#   host                   = "https://${module.cluster.container_cluster.endpoint}"
#   cluster_ca_certificate = base64decode(module.cluster.container_cluster.master_auth.0.cluster_ca_certificate)
#   token                  = data.google_client_config.default.access_token
#   }
# }

provider "metropolis" {
  host        = "http://hellometropolis.com"

  public_key  = var.metropolis_public_key
  private_key = var.metropolis_public_key
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

# data "kubernetes_service" "nginx_ingress_controller" {
#   metadata {
#     name = "${helm_release.nginx_ingress.name}-controller"
#   }

#   # Wait to build the ingress before refreshing the
#   # kubernetes service
#   depends_on = [
#     helm_release.nginx_ingress,
#   ]

# }

# ###############################################################################
# # Misc
# ###############################################################################
# resource "helm_release" "nginx_ingress" {
#   name       = "nginx-ingress-production"
#   chart      = "stable/nginx-ingress"
# }