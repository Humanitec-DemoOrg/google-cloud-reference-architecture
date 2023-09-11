terraform {
  required_providers {
    humanitec = {
      source = "humanitec/humanitec"
      version = "0.12.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "4.81.0"
    }
    github = {
      source = "integrations/github"
      version = "5.35.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.11.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0"
    }
    http = {
      source = "hashicorp/http"
      version = "3.4.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "humanitec" {
  org_id = var.humanitec_credentials.organization
  token  = var.humanitec_credentials.token
}

provider "google" {
  project = var.gcp_project_id
}

provider "github" {
  owner = var.github_credentials.organization
  token = var.github_credentials.token
}

provider "helm" {
  kubernetes {
    host                    = "https://${google_container_cluster.gke.endpoint}"
    token                   = data.google_client_config.default.access_token
    cluster_ca_certificate  = base64decode(
      google_container_cluster.gke.master_auth.0.cluster_ca_certificate
    )
  }
}

provider "kubernetes" {
  host                    = "https://${google_container_cluster.gke.endpoint}"
  token                   = data.google_client_config.default.access_token
  cluster_ca_certificate  = base64decode(
    google_container_cluster.gke.master_auth.0.cluster_ca_certificate
  )
}