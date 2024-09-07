terraform {
  required_providers {
    kubernetes = {
      source  = "opentofu/kubernetes"
      version = "2.32.0"
    }
    null = {
      source  = "opentofu/null"
      version = "3.2.2"
    }
  }

  backend "kubernetes" {
    secret_suffix = "certificates.minio"
    config_path   = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "null" {

}
