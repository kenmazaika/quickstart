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

resource "metropolis_asset" "metropolis_asset_ingress_ip" {
  name  = "INGRESS_IP_ADDRESS"
  value = data.kubernetes_service.nginx_ingress_controller.load_balancer_ingress.0.ip

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

resource "metropolis_component" "mount_secrets" {
  name              = "mount-secrets"
  container_name    = "gcr.io/cloud-builders/gcloud"
  workspace_id      = metropolis_workspace.primary.id

  component_did_mount = [
    "echo 'Mounting secrets to /workspace/.metropolis-secrets'", 
    "mkdir -p /workspace/.metropolis-secrets/metropolis-quickstart-rails-master-key", 
    "echo `gcloud secrets versions access latest --secret metropolis-quickstart-rails-master-key` > /workspace/.metropolis-secrets/metropolis-quickstart-rails-master-key/value", 
    "mkdir -p /workspace/.metropolis-secrets/metropolis-quickstart-database-credentials", 
    "echo `gcloud secrets versions access latest --secret metropolis-quickstart-database-password` > /workspace/.metropolis-secrets/metropolis-quickstart-database-credentials/password"
  ]

  skip = [ "update", "destroy" ]

}

resource "metropolis_component" "rake_database" {
  name              = "rake-database"
  container_name    = "${var.docker_repo_backend}:$_METROPOLIS_PLACEHOLDER.DOCKER_TAG"
  placeholders      = [ "SANDBOX_ID" ]
  workspace_id      = metropolis_workspace.primary.id

  component_did_mount = [
    "curl https://raw.githubusercontent.com/kenmazaika/metropolis-utils/master/scripts/cloud_sql_proxy/install.sh | sh",
    ". /metropolis-utils/.metropolis-utils && PROXY_INSTANCE_NAME=\"$_METROPOLIS_ASSET.DATABASE_INSTANCE_NAME\" SANDBOX_ID=\"$_METROPOLIS_PLACEHOLDER.SANDBOX_ID\" sh backend/lib/docker/setup-cloudproxy-and-mount.sh"
  ]

  on_create = [
    "cd backend && RAILS_ENV=production rake quickstart:seed"
  ]

  skip = [ "update", "destroy" ]

}

resource "metropolis_component" "expose_services" {
  name              = "kubernetes-ingress"
  container_name    = "gcr.io/cloud-builders/gcloud"
  placeholders      = [ "SANDBOX_ID" ]
  workspace_id      = metropolis_workspace.primary.id

  on_create = [
    "gcloud container clusters get-credentials ${var.cluster_name} --zone=us-west1", 
    "DEPLOYMENT_KEY=$_METROPOLIS_PLACEHOLDER.SANDBOX_ID INGRESS_HOST=$_METROPOLIS_PLACEHOLDER.SANDBOX_ID.${var.domain_name} sh ./infrastructure/shell/install-ingress.sh"
  ]

  skip = [ "update", "destroy" ]  

}

resource "metropolis_component" "dns" {
  name              = "setup-dns-records"
  container_name    = "gcr.io/cloud-builders/gcloud"
  workspace_id      = metropolis_workspace.primary.id

  placeholders = ["SANDBOX_ID" ]

  component_did_mount = [
    "curl https://raw.githubusercontent.com/kenmazaika/metropolis-utils/master/scripts/terraform/install.sh | sh",
    ". /metropolis-utils/.metropolis-utils"
  ]

  on_create = [
    "cd ./infrastructure/shell/dns-records", 
    "gcloud secrets versions access latest --secret metropolis-quickstart-gcp-service-account > gcp-service-account.json", 
    "terraform init", 
    "terraform apply -var 'domain=$_METROPOLIS_PLACEHOLDER.SANDBOX_ID.${var.domain_name}' -var 'ip_address=$_METROPOLIS_ASSET.INGRESS_IP_ADDRESS' --auto-approve",
    "echo 'METRO_INFO: {\"url\": \"$_METROPOLIS_PLACEHOLDER.SANDBOX_ID.${var.domain_name}\"}'"
  ]

  on_destroy = [
    "cd ./infrastructure/shell/dns-records", 
    "gcloud secrets versions access latest --secret metropolis-quickstart-gcp-service-account > gcp-service-account.json", 
    "terraform init", 
    "terraform destroy -var 'domain=$_METROPOLIS_PLACEHOLDER.SANDBOX_ID.${var.domain_name}' -var 'ip_address=$_METROPOLIS_ASSET.INGRESS_IP_ADDRESS' --auto-approve"
  ]

  skip = [ "update" ]
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

  component {
    id = metropolis_component.mount_secrets.id
  }

  component {
    id = metropolis_component.rake_database.id
  }

  component {
    id = metropolis_component.expose_services.id
  }

  component {
    id = metropolis_component.dns.id
  }

}

###############################################################################
# Metropolis Deployment
###############################################################################

resource "metropolis_deployment" "master" {
  name           = "master"
  composition_id = metropolis_composition.primary.id
  state          = "build"

  placeholder {
    name  = "DOCKER_TAG"
    value = "latest"
  }

  placeholder {
    name  = "SANDBOX_ID"
    value = "master"
  }

  placeholder {
    name  = "METROPOLIS_BRANCH"
    value = "master"
  }

  placeholder {
    name  = "METROPOLIS_REF"
    value = "master"
  }

  placeholder {
    name  = "METROPOLIS_REPO"
    value = "kenmazaika/metropolis"
  }

  event_link {
    repo           = "kenmazaika/metropolis"
    event_name     = "pull_request"
    branch         = "master"
    trigger_action = "upgrade"
  }

}