// Cluster Issuer for PhotoAtom Application
resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "${var.cluster_issuer_name}"
      "labels" = {
        "app"       = "minio"
        "component" = "clusterissuer"
      }
    }
    "spec" = {
      "selfSigned" = {}
    }
  }
}

// Certificate Authority to be used with MinIO Operator
resource "kubernetes_manifest" "minio_ca" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${var.minio_ca_name}"
      "namespace" = "${var.minio_operator_namespace}"
      "labels" = {
        "app"       = "minio"
        "component" = "ca"
      }
    }
    "spec" = {
      "isCA"       = true
      "commonName" = "operator"
      "secretName" = "operator-ca-tls"
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

  depends_on = [kubernetes_manifest.cluster_issuer]
}

// Issuer for the MinIO Operator Namespace
resource "kubernetes_manifest" "minio_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "${var.minio_issuer_name}"
      "namespace" = "${var.minio_operator_namespace}"
      "labels" = {
        "app"       = "minio"
        "component" = "issuer"
      }
    }
    "spec" = {
      "ca" = {
        "secretName" = "operator-ca-tls"
      }
    }
  }

  depends_on = [kubernetes_manifest.minio_ca]
}

// Certificate for MinIO STS
resource "kubernetes_manifest" "sts_certificate" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${var.minio_sts_certificate_name}"
      "namespace" = "${var.minio_operator_namespace}"
      "labels" = {
        "app"       = "minio"
        "component" = "certificate"
      }
    }
    "spec" = {
      "dnsNames" = [
        "sts",
        "sts.minio-operator.svc",
        "sts.minio-operator.svc.cluster.local"
      ]
      "secretName" = "sts-tls"
      "issuerRef" = {
        "name" = "${var.minio_issuer_name}"
      }
    }
  }

  depends_on = [kubernetes_manifest.minio_issuer]
}

// Null resource to restart the MinIO Operator
resource "null_resource" "minio_restart" {
  triggers = {
    "restart" : true
  }

  provisioner "local-exec" {
    command = "sleep 30; kubectl rollout restart deployments.apps/minio-operator -n minio-operator; sleep 30"
  }
  depends_on = [kubernetes_manifest.sts_certificate]
}

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

  depends_on = [null_resource.minio_restart]
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

// Null resource to restart the MinIO Operator
resource "null_resource" "minio_tenant_restart" {
  triggers = {
    "restart_tenant" : true
  }

  provisioner "local-exec" {
    command = "sleep 30; kubectl get secrets -n minio minio-tls -o=jsonpath='{.data.ca\\.crt}' | base64 -d > ca.crt; kubectl create secret generic operator-ca-tls-photoatom-object-storage --from-file=ca.crt -n minio-operator; kubectl rollout restart deployments.apps/minio-operator -n minio-operator; rm ca.crt; sleep 30"
  }
  depends_on = [kubernetes_manifest.tenant_certificate]
}
