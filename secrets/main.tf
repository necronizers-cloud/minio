// Passwords for MinIO Tenant Users
resource "random_password" "root_password" {
  length           = 16
  lower            = true
  numeric          = true
  special          = true
  override_special = "-_*/"
  min_special      = 2
}

resource "random_password" "app_password" {
  length           = 16
  lower            = true
  numeric          = true
  special          = true
  override_special = "-_*/"
  min_special      = 2
}

resource "random_password" "postgres_password" {
  length           = 16
  lower            = true
  numeric          = true
  special          = true
  override_special = "-_*/"
  min_special      = 2
}

// MinIO Storage Configuration
resource "kubernetes_secret" "storage_configuration" {
  metadata {
    name      = var.storage_configuration_name
    namespace = var.namespace

    labels = {
      app       = "minio"
      component = "secret"
    }
  }

  data = {
    "config.env" = <<EOT
export MINIO_ROOT_USER="minio"
export MINIO_ROOT_PASSWORD="${random_password.root_password.result}"
export MINIO_STORAGE_CLASS_STANDARD="EC:2"
export MINIO_BROWSER="on"
EOT
  }

  type = "Opaque"
}

// MinIO Users Configuration
resource "kubernetes_secret" "app_user" {
  metadata {
    name      = var.app_user_name
    namespace = var.namespace

    labels = {
      app       = "minio"
      component = "secret"
    }
  }

  data = {
    CONSOLE_ACCESS_KEY = "app"
    CONSOLE_SECRET_KEY = "${random_password.app_password.result}"
  }

  type = "Opaque"
}

resource "kubernetes_secret" "postgres_user" {
  metadata {
    name      = var.postgres_user_name
    namespace = var.namespace

    labels = {
      app       = "minio"
      component = "secret"
    }
  }

  data = {
    CONSOLE_ACCESS_KEY = "postgres"
    CONSOLE_SECRET_KEY = "${random_password.postgres_password.result}"
  }

  type = "Opaque"
}
