// Namespace for MinIO Components
resource "kubernetes_namespace" "minio" {
  metadata {
    name = "minio"
    labels = {
      app       = "minio"
      component = "namespace"
    }
  }
}