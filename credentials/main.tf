// Generating MinIO Access Key for Postgres Backups
resource "random_password" "postgres_backups_access_secret" {
  length           = 16
  lower            = true
  numeric          = true
  special          = true
  override_special = "-_*"
  min_special      = 2
}

resource "kubernetes_secret" "postgres_backups_access_keys" {
  metadata {
    name      = var.postgres_backups_access_credentials
    namespace = var.namespace

    labels = {
      app       = "minio"
      component = "secret"
    }
  }

  data = {
    "MINIO_USER"          = "postgres"
    "MINIO_ACCESS_KEY"    = var.postgres_service_account_name
    "MINIO_ACCESS_SECRET" = random_password.postgres_backups_access_secret.result
  }

  type = "Opaque"
}
