###############################################################################
# Metropolis Workspace
###############################################################################

resource "metropolis_workspace" "primary" {
  name = "Metropolis Quickstart"
  note = "Workspace for the metropolis quickstart application"
}

###############################################################################
# Metropolis Assets
###############################################################################

resource "metropolis_asset" "metropolis_asset_database_name" {
  name  = "DATABASE_NAME"
  value = google_sql_database_instance.master.name

  workspace_id = metropolis_workspace.primary.id
}

resource "metropolis_asset" "metropolis_asset_database_instance_name" {
  name  = "DATABASE_INSTANCE_NAME"
  value = "${var.project}:${var.region}:${google_sql_database_instance.master.name}"

  workspace_id = metropolis_workspace.primary.id
}

resource "metropolis_asset" "metropolis_asset_database_private_ip" {
  name  = "DATABASE_PRIVATE_IP"
  value = google_sql_database_instance.master.ip_address[index(google_sql_database_instance.master.ip_address.*.type, "PRIVATE")].ip_address

  workspace_id = metropolis_workspace.primary.id
}


###############################################################################
# Metropolis Component
###############################################################################
resource "metropolis_component" "clone_source" {
  name              = "clone-source"
  container_name    = "gcr.io/cloud-builders/gcloud"
  placeholders      = [ "METROPOLIS_REF" ]
  workspace_id      = metropolis_workspace.primary.id

  component_did_mount = [
    "curl https://raw.githubusercontent.com/kenmazaika/metropolis-utils/master/scripts/github/clone.sh | DEPLOY_KEY=\"`gcloud secrets versions access latest --secret=github_deploy_key`\" GITHUB_URL=\"${var.github_clone_url}\" REF=\"$_METROPOLIS_PLACEHOLDER.METROPOLIS_REF\" sh",
    ". /metropolis-utils/.clone",
    "ls"
  ]
  
}
resource "metropolis_component" "docker_build_frontend" {
  name              = "docker-build-frontend"
  container_name    = "gcr.io/kaniko-project/executor:v0.18.0"
  placeholders      = [ "DOCKER_TAG" ]
  workspace_id      = metropolis_workspace.primary.id
  
  arguments = [
    "--dockerfile=frontend/Dockerfile",
    "--context=dir://frontend",
    "--destination=${var.docker_repo_frontend}:$_METROPOLIS_PLACEHOLDER.DOCKER_TAG",
    "--cache=true",
    "--cache-ttl=24h"
  ]

  skip = [ "destroy" ]
}
resource "metropolis_component" "docker_build_backend" {
  name              = "docker-build-backend"
  container_name    = "gcr.io/kaniko-project/executor:v0.18.0"
  placeholders      = [ "DOCKER_TAG" ]
  workspace_id      = metropolis_workspace.primary.id
  
  arguments = [
    "--dockerfile=backend/Dockerfile",
    "--context=dir://backend",
    "--destination=${var.docker_repo_backend}:$_METROPOLIS_PLACEHOLDER.DOCKER_TAG",
    "--cache=true",
    "--cache-ttl=24h"
  ]

  skip = [ "destroy" ]
}


resource "metropolis_component" "helm_releases" {
  name              = "helm-deployments"
  container_name    = "gcr.io/cloud-builders/gcloud"
  placeholders      = [ "SANDBOX_ID", "DOCKER_TAG" ]
  workspace_id      = metropolis_workspace.primary.id

  component_did_mount = [
    "curl https://raw.githubusercontent.com/kenmazaika/metropolis-utils/master/scripts/helm/install.sh | sh",
    ". /metropolis-utils/.metropolis-utils"
  ]

  on_create = [
    "gcloud container clusters get-credentials ${var.cluster_name} --zone=us-west1", 
    "helm install frontend-$_METROPOLIS_PLACEHOLDER.SANDBOX_ID infrastructure/helm/frontend/ --set image.tag=$_METROPOLIS_PLACEHOLDER.DOCKER_TAG", 
    "helm install backend-$_METROPOLIS_PLACEHOLDER.SANDBOX_ID infrastructure/helm/backend/ --set image.tag=$_METROPOLIS_PLACEHOLDER.DOCKER_TAG --set env.RAILS_ENV=production --set env.AFTER_CONTAINER_DID_MOUNT=\"sh lib/docker/mount.sh\" --set env.SANDBOX_ID=$_METROPOLIS_PLACEHOLDER.SANDBOX_ID"
  ]

  on_update = [
    "gcloud container clusters get-credentials ${var.cluster_name} --zone=us-west1", 
    "helm upgrade frontend-$_METROPOLIS_PLACEHOLDER.SANDBOX_ID infrastructure/helm/frontend/ --set image.tag=$_METROPOLIS_PLACEHOLDER.DOCKER_TAG", 
    "helm upgrade backend-$_METROPOLIS_PLACEHOLDER.SANDBOX_ID infrastructure/helm/backend/ --set image.tag=$_METROPOLIS_PLACEHOLDER.DOCKER_TAG --set env.RAILS_ENV=production --set env.AFTER_CONTAINER_DID_MOUNT=\"sh lib/docker/mount.sh\" --set env.SANDBOX_ID=$_METROPOLIS_PLACEHOLDER.SANDBOX_ID"
  ]

  on_destroy = [
    "gcloud container clusters get-credentials ${var.cluster_name} --zone=us-west1", 
    "helm delete frontend-$_METROPOLIS_PLACEHOLDER.SANDBOX_ID", 
    "helm delete backend-$_METROPOLIS_PLACEHOLDER.SANDBOX_ID"
  ]

}


###############################################################################
# Metropolis Composition
###############################################################################

resource "metropolis_composition" "primary" {
  name              = "Sandbox"
  workspace_id      = metropolis_workspace.primary.id

  component {
    id = metropolis_component.clone_source.id
  }

  component {
    id = metropolis_component.docker_build_frontend.id
  }

  component {
    id = metropolis_component.docker_build_backend.id
  }

  component {
    id = metropolis_component.helm_releases.id
  }

}










# resource "metropolis_asset" "metropolis_asset_ingress_ip" {
#   name  = "INGRESS_IP_ADDRESS"
#   value = var.ingress_ip_address

#   workspace_id = metropolis_workspace.primary.id
# }



# resource "metropolis_component" "helm_releases" {
#   name              = "helm-deployments"
#   container_name    = "gcr.io/cloud-builders/gcloud"
#   placeholders      = [ "SANDBOX_ID", "DOCKER_TAG", "REDIS_HOST" ]
#   workspace_id      = metropolis_workspace.primary.id

#   component_did_mount = [
#     "curl https://raw.githubusercontent.com/kenmazaika/metropolis-utils/master/scripts/helm/install.sh | sh",
#     ". /metropolis-utils/.metropolis-utils"
#   ]

#   on_create = [
#     "gcloud container clusters get-credentials ${var.cluster_name} --zone=us-west1", 
#     "helm install frontend-$_METROPOLIS_PLACEHOLDER.SANDBOX_ID infrastructure/helm/frontend/ --set image.tag=$_METROPOLIS_PLACEHOLDER.DOCKER_TAG", 
#     "helm install backend-$_METROPOLIS_PLACEHOLDER.SANDBOX_ID infrastructure/helm/backend/ --set image.tag=$_METROPOLIS_PLACEHOLDER.DOCKER_TAG --set env.RAILS_ENV=${var.environment} --set env.AFTER_CONTAINER_DID_MOUNT=\"sh lib/docker/mount-${var.environment}.sh\" --set env.SANDBOX_ID=$_METROPOLIS_PLACEHOLDER.SANDBOX_ID --set env.REDIS_HOST=$_METROPOLIS_ASSET.REDIS_HOST"
#   ]

#   on_update = [
#     "gcloud container clusters get-credentials ${var.cluster_name} --zone=us-west1", 
#     "helm upgrade frontend-$_METROPOLIS_PLACEHOLDER.SANDBOX_ID infrastructure/helm/frontend/ --set image.tag=$_METROPOLIS_PLACEHOLDER.DOCKER_TAG", 
#     "helm upgrade backend-$_METROPOLIS_PLACEHOLDER.SANDBOX_ID infrastructure/helm/backend/ --set image.tag=$_METROPOLIS_PLACEHOLDER.DOCKER_TAG --set env.RAILS_ENV=${var.environment} --set env.AFTER_CONTAINER_DID_MOUNT=\"sh lib/docker/mount-${var.environment}.sh\" --set env.SANDBOX_ID=$_METROPOLIS_PLACEHOLDER.SANDBOX_ID --set env.REDIS_HOST=$_METROPOLIS_ASSET.REDIS_HOST"
#   ]

#   on_destroy = [
#     "gcloud container clusters get-credentials ${var.cluster_name} --zone=us-west1", 
#     "helm delete frontend-$_METROPOLIS_PLACEHOLDER.SANDBOX_ID", 
#     "helm delete backend-$_METROPOLIS_PLACEHOLDER.SANDBOX_ID"
#   ]


# }

# resource "metropolis_component" "rake_database" {
#   name              = "rake-database"
#   container_name    = "gcr.io/hello-metropolis/metropolis/backend:latest"
#   placeholders      = [ "SANDBOX_ID" ]
#   workspace_id      = metropolis_workspace.primary.id
#   count             = var.seed_database ? "1" : "0"

#   component_did_mount = [
#     "curl https://raw.githubusercontent.com/kenmazaika/metropolis-utils/master/scripts/cloud_sql_proxy/install.sh | sh",
#     ". /metropolis-utils/.metropolis-utils && PROXY_INSTANCE_NAME=\"$_METROPOLIS_ASSET.DATABASE_INSTANCE_NAME\" SANDBOX_ID=\"$_METROPOLIS_PLACEHOLDER.SANDBOX_ID\" sh backend/lib/docker/setup-cloudproxy-and-mount-${var.environment}.sh"
#   ]

#   on_create = [
#     "cd backend && RAILS_ENV=${var.environment} rake metropolis:seed"
#   ]

#   skip = [ "update", "destroy" ]

# }

# resource "metropolis_component" "expose_services" {
#   name              = "kubernetes-ingress"
#   container_name    = "gcr.io/cloud-builders/gcloud"
#   placeholders      = [ "SANDBOX_ID", "CUSTOM_DOMAIN" ]
#   workspace_id      = metropolis_workspace.primary.id

#   on_create = [
#     "gcloud container clusters get-credentials ${var.cluster_name} --zone=us-west1", 
#     "DEPLOYMENT_KEY=$_METROPOLIS_PLACEHOLDER.SANDBOX_ID INGRESS_HOST=$_METROPOLIS_PLACEHOLDER.CUSTOM_DOMAIN sh ./infrastructure/shell/install-${var.environment}-ingress.sh"
#   ]

#   skip = [ "update", "destroy" ]  

# }


# resource "metropolis_component" "mount_secrets" {
#   name              = "mount-secrets"
#   container_name    = "gcr.io/cloud-builders/gcloud"
#   workspace_id      = metropolis_workspace.primary.id

#   component_did_mount = [
#     "echo 'Mounting secrets to /workspace/.metropolis-secrets'", 
#     "mkdir -p /workspace/.metropolis-secrets/metropolis-rails-master-key", 
#     "echo `gcloud secrets versions access latest --secret metropolis-rails-master-key` > /workspace/.metropolis-secrets/metropolis-rails-master-key/value", 
#     "mkdir -p /workspace/.metropolis-secrets/metropolis-database-credentials", 
#     "echo `gcloud secrets versions access latest --secret metropolis-database-password-${var.environment}` > /workspace/.metropolis-secrets/metropolis-database-credentials/password"
#   ]

#   skip = [ "update", "destroy" ]

# }

# resource "metropolis_component" "dns" {
#   name              = "setup-dns-records"
#   container_name    = "gcr.io/cloud-builders/gcloud"
#   workspace_id      = metropolis_workspace.primary.id

#   placeholders = ["SANDBOX_ID", "CUSTOM_DOMAIN"]

#   component_did_mount = [
#     "curl https://raw.githubusercontent.com/kenmazaika/metropolis-utils/master/scripts/terraform/install.sh | sh",
#     ". /metropolis-utils/.metropolis-utils"
#   ]

#   on_create = [
#     "cd ./infrastructure/metropolis/${var.environment}/dns-records", 
#     "gcloud secrets versions access latest --secret metropolis-gcp-service-account > gcp-service-account.json", 
#     "terraform init", 
#     "terraform apply -var 'domain=$_METROPOLIS_PLACEHOLDER.CUSTOM_DOMAIN' -var 'ip_address=$_METROPOLIS_ASSET.INGRESS_IP_ADDRESS' --auto-approve",
#     "echo 'METRO_INFO: {\"url\": \"$_METROPOLIS_PLACEHOLDER.CUSTOM_DOMAIN\"}'"
#   ]

#   on_destroy = [
#     "cd ./infrastructure/metropolis/${var.environment}/dns-records", 
#     "gcloud secrets versions access latest --secret metropolis-gcp-service-account > gcp-service-account.json", 
#     "terraform init", 
#     "terraform destroy -var 'domain=$_METROPOLIS_PLACEHOLDER.CUSTOM_DOMAIN' -var 'ip_address=$_METROPOLIS_ASSET.INGRESS_IP_ADDRESS' --auto-approve"
#   ]

#   skip = [ "update" ]
# }

# locals {
#   metropolis_component_ids = concat(
#       [
#       metropolis_component.clone_source.id,
#       metropolis_component.docker_build_frontend.id,
#       metropolis_component.docker_build_backend.id,
#       metropolis_component.helm_releases.id,
#       metropolis_component.mount_secrets.id
#     ], 
#     (var.seed_database ? [metropolis_component.rake_database[0].id] : []),
#     [
#       metropolis_component.dns.id,
#       metropolis_component.expose_services.id
#     ]
#   )

#   composition_event_links = var.environment == "production" ? [] : [
#     {
#       repo           = "kenmazaika/metropolis"
#       event_name     = "pull_request"
#       branch         = "*"
#       trigger_action = "build"
#       spawn_sync     = true
#     }
#   ]
# }

# resource "metropolis_composition" "primary" {
#   name              = "Sandbox"
#   workspace_id      = metropolis_workspace.primary.id

#   dynamic "component" {
#     for_each = local.metropolis_component_ids

#     content {
#         id = component.value
#     }
#   }

#   depends_on = [
#     metropolis_asset.metropolis_asset_database_name,
#     metropolis_asset.metropolis_asset_database_instance_name,
#     metropolis_asset.metropolis_asset_database_private_ip,
#     metropolis_asset.metropolis_asset_ingress_ip
#   ]

#   dynamic "event_link" {
#     for_each = local.composition_event_links

#     content {
#       repo           = event_link.value.repo
#       event_name     = event_link.value.event_name
#       branch         = event_link.value.branch
#       trigger_action = event_link.value.trigger_action
#       spawn_sync     = event_link.value.spawn_sync
#     }
#   }

# }

# locals {
#   deployment_event_links = var.environment == "production" ? [] : [
#     {
#       repo           = "kenmazaika/metropolis"
#       event_name     = "pull_request"
#       branch         = "master"
#       trigger_action = "upgrade"
#     }
#   ]
# }

# resource "metropolis_deployment" "master" {
#   name           = "master"
#   composition_id = metropolis_composition.primary.id
#   state          = "build"

#   placeholder {
#     name  = "DOCKER_TAG"
#     value = "latest"
#   }

#   placeholder {
#     name  = "SANDBOX_ID"
#     value = var.environment
#   }

#   placeholder {
#     name  = "METROPOLIS_BRANCH"
#     value = "master"
#   }

#   placeholder {
#     name  = "METROPOLIS_REF"
#     value = "master"
#   }

#   placeholder {
#     name  = "METROPOLIS_REPO"
#     value = "kenmazaika/metropolis"
#   }

#   placeholder {
#     name  = "CUSTOM_DOMAIN"
#     value = "hellometropolis.com"
#   }


#   dynamic "event_link" {
#     for_each = local.deployment_event_links

#     content {
#       repo           = event_link.value.repo
#       event_name     = event_link.value.event_name
#       branch         = event_link.value.branch
#       trigger_action = event_link.value.trigger_action
#       spawn_sync     = event_link.value.spawn_sync
#     }
#   }

# }