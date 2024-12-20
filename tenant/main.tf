resource "kubernetes_service_account" "minio_service_account" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
    labels = {
      app       = "minio"
      component = "serviceaccount"
    }
  }
}

resource "kubernetes_role" "minio_service_account_role" {
  metadata {
    name      = var.role_name
    namespace = var.namespace
    labels = {
      app       = "minio"
      component = "role"
    }
  }

  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = [var.storage_configuration_name, "photoatom-user", "postgres-user", "minio-tls"]
    verbs          = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "minio_service_account_role_binding" {
  metadata {
    name      = var.role_binding_name
    namespace = var.namespace
    labels = {
      app       = "minio"
      component = "rolebinding"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = var.role_name
  }
  subject {
    kind      = "ServiceAccount"
    name      = var.service_account_name
    namespace = var.namespace
  }

  depends_on = [kubernetes_role.minio_service_account_role, kubernetes_service_account.minio_service_account]
}

resource "kubernetes_manifest" "minio_tenant" {
  manifest = {
    "apiVersion" = "minio.min.io/v2"
    "kind"       = "Tenant"
    "metadata" = {
      "annotations" = {
        "prometheus.io/path"   = "/minio/v2/metrics/cluster"
        "prometheus.io/port"   = "9000"
        "prometheus.io/scrape" = "true"
      }
      "labels" = {
        "app"       = "minio"
        "component" = "tenant"
      }
      "name"      = "minio"
      "namespace" = "${var.namespace}"
    }
    "spec" = {
      "buckets" = var.bucket_names
      "configuration" = {
        "name" = var.storage_configuration_name
      }
      "externalCertSecret" = [
        {
          "name" = "minio-tls"
          "type" = "cert-manager.io/v1"
        },
      ]
      "image"               = "quay.io/minio/minio:RELEASE.2024-08-03T04-33-23Z"
      "mountPath"           = "/export"
      "podManagementPolicy" = "Parallel"
      "pools" = [
        {
          "containerSecurityContext" = {
            "allowPrivilegeEscalation" = false
            "capabilities" = {
              "drop" = [
                "ALL",
              ]
            }
            "runAsGroup"   = 1000
            "runAsNonRoot" = true
            "runAsUser"    = 1000
            "seccompProfile" = {
              "type" = "RuntimeDefault"
            }
          }
          "name" = "storage"
          "resources" = {
            "limits" = {
              "cpu"    = "500m"
              "memory" = "500Mi"
            }
            "requests" = {
              "cpu"    = "100m"
              "memory" = "100Mi"
            }
          }
          "securityContext" = {
            "fsGroup"             = 1000
            "fsGroupChangePolicy" = "OnRootMismatch"
            "runAsGroup"          = 1000
            "runAsNonRoot"        = true
            "runAsUser"           = 1000
          }
          "servers" = 4
          "volumeClaimTemplate" = {
            "apiVersion" = "v1"
            "kind"       = "persistentvolumeclaims"
            "metadata" = {
              "namespace" = "${var.namespace}"
              "labels" = {
                "app"       = "minio"
                "component" = "pvc"
              }
            }
            "spec" = {
              "accessModes" = [
                "ReadWriteOnce",
              ]
              "resources" = {
                "requests" = {
                  "storage" = "5Gi"
                }
              }
              "storageClassName" = "local-path"
            }
          }
          "volumesPerServer" = 1
        },
      ]
      "priorityClassName"  = ""
      "requestAutoCert"    = false
      "serviceAccountName" = var.service_account_name
      "serviceMetadata" = {
        "consoleServiceLabels" = {
          "app"       = "minio"
          "component" = "service"
        }
        "minioServiceLabels" = {
          "app"       = "minio"
          "component" = "service"
        }
      }
      "subPath" = ""
      "users" = [
        {
          "name" = var.photoatom_user_name
        },
        {
          "name" = var.postgres_user_name
        },
      ]
    }
  }

  depends_on = [kubernetes_role_binding.minio_service_account_role_binding]
}

resource "kubernetes_ingress_v1" "minio_ingress" {
  metadata {
    name      = "minio-ingress"
    namespace = var.namespace
    labels = {
      app       = "minio"
      component = "ingress"
    }
    annotations = {
      "nginx.ingress.kubernetes.io/proxy-ssl-verify" : "off"
      "nginx.ingress.kubernetes.io/backend-protocol" : "HTTPS"
      "nginx.ingress.kubernetes.io/rewrite-target" : "/"
      "nginx.ingress.kubernetes.io/proxy-body-size" : 0
    }
  }

  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = ["${var.host_name}.${var.photoatom_domain}"]
      secret_name = "minio-ingress-tls"
    }
    rule {
      host = "${var.host_name}.${var.photoatom_domain}"
      http {
        path {
          path = "/"
          backend {
            service {
              name = "minio-console"
              port {
                number = 9443
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_manifest.minio_tenant]
}
