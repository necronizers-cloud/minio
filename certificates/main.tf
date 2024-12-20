// Certificate Authority to be used with MinIO Tenant
resource "kubernetes_manifest" "minio_tenant_ca" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${var.minio_tenant_ca_name}"
      "namespace" = "${var.namespace}"
      "labels" = {
        "app"       = "minio"
        "component" = "ca"
      }
    }
    "spec" = {
      "isCA" = true
      "subject" = {
        "organizations"       = ["photoatom"]
        "countries"           = ["India"]
        "organizationalUnits" = ["MinIO"]
      }
      "commonName" = "minio-ca-certificate"
      "secretName" = "minio-ca-certificate-tls"
      "duration"   = "70128h"
      "privateKey" = {
        "algorithm" = "ECDSA"
        "size"      = 256
      }
      "issuerRef" = {
        "name"  = "${var.cluster_issuer_name}"
        "kind"  = "ClusterIssuer"
        "group" = "cert-manager.io"
      }
    }
  }
}

// Issuer to be used with MinIO Tenant
resource "kubernetes_manifest" "minio_tenant_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "${var.minio_tenant_issuer_name}"
      "namespace" = "${var.namespace}"
      "labels" = {
        "app"       = "minio"
        "component" = "issuer"
      }
    }
    "spec" = {
      "ca" = {
        "secretName" = "minio-ca-certificate-tls"
      }
    }
  }

  depends_on = [kubernetes_manifest.minio_tenant_ca]
}

// Certificate for MinIO Tenant
resource "kubernetes_manifest" "tenant_certificate" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${var.minio_tenant_certificate_name}"
      "namespace" = "${var.namespace}"
      "labels" = {
        "app"       = "minio"
        "component" = "certificate"
      }
    }
    "spec" = {
      "dnsNames" = [
        "minio.minio",
        "minio.minio.svc",
        "minio.minio.svc.cluster.local",
        "*.minio.minio.svc.cluster.local",
        "*.minio-hl.minio.svc.cluster.local",
        "minio-hl.minio.svc.cluster.local",
        "*.minio.minio.minio.svc.cluster.local",
      ]
      "subject" = {
        "organizations"       = ["photoatom"]
        "countries"           = ["India"]
        "organizationalUnits" = ["MinIO"]
      }
      "commonName" = "minio"
      "secretName" = "minio-tls"
      "issuerRef" = {
        "name" = "${var.minio_tenant_issuer_name}"
      }
    }
  }

  depends_on = [kubernetes_manifest.minio_tenant_issuer]
}


// Kubernetes Secret for Cloudflare Tokens
resource "kubernetes_secret" "cloudflare_token" {
  metadata {
    name      = "cloudflare-token"
    namespace = var.namespace
    labels = {
      "app"       = "minio"
      "component" = "secret"
    }

  }

  data = {
    cloudflare-token = var.cloudflare_token
  }

  type = "Opaque"
}

// Cloudflare Issuer for MinIO Ingress Service
resource "kubernetes_manifest" "minio_public_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "minio-public-issuer"
      "namespace" = var.namespace
      "labels" = {
        "app"       = "minio"
        "component" = "issuer"
      }
    }
    "spec" = {
      "acme" = {
        "email"  = var.cloudflare_email
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "privateKeySecretRef" = {
          "name" = "minio-issuer-key"
        }
        "solvers" = [
          {
            "dns01" = {
              "cloudflare" = {
                "email" = var.cloudflare_email
                "apiTokenSecretRef" = {
                  "name" = "cloudflare-token"
                  "key"  = "cloudflare-token"
                }
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [kubernetes_secret.cloudflare_token]
}

// Certificate to be used for MinIO Ingress
resource "kubernetes_manifest" "minio_ingress_certificate" {

  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "minio-ingress-certificate"
      "namespace" = var.namespace
      "labels" = {
        "app"       = "minio"
        "component" = "certificate"
      }
    }
    "spec" = {
      "duration"    = "2160h"
      "renewBefore" = "360h"
      "subject" = {
        "organizations"       = ["photoatom"]
        "countries"           = ["India"]
        "organizationalUnits" = ["MinIO"]
      }
      "privateKey" = {
        "algorithm" = "RSA"
        "encoding"  = "PKCS1"
        "size"      = "2048"
      }
      "dnsNames"   = ["${var.host_name}.${var.photoatom_domain}"]
      "secretName" = "minio-ingress-tls"
      "issuerRef" = {
        "name"  = "minio-public-issuer"
        "kind"  = "Issuer"
        "group" = "cert-manager.io"
      }
    }
  }

  depends_on = [kubernetes_manifest.minio_public_issuer]

}
