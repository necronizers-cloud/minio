terraform {
  required_providers {
    kubernetes = {
      source  = "opentofu/kubernetes"
      version = "2.32.0"
    }
    random = {
      source  = "opentofu/random"
      version = "3.6.2"
    }
  }

  backend "kubernetes" {
    secret_suffix = "secrets.minio"
    config_path   = "~/.kube/config"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "random" {

}
