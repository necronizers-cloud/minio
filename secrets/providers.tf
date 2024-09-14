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
  }
}

provider "kubernetes" {

}

provider "random" {

}
