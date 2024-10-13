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
      "isCA"       = true
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
      "secretName" = "minio-tls"
      "issuerRef" = {
        "name" = "${var.minio_tenant_issuer_name}"
      }
    }
  }

  depends_on = [kubernetes_manifest.minio_tenant_issuer]
}
