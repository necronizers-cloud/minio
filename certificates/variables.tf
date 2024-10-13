# ------------ MINIO TENANT VARIABLES ------------ #

variable "namespace" {
  default     = "minio"
  description = "Namespace to be used for deploying MinIO Tenant and related resources."
}

variable "minio_tenant_ca_name" {
  default     = "minio-ca"
  description = "Name for the Certificate Authority for MinIO"
}

variable "minio_tenant_issuer_name" {
  default     = "minio-ca-issuer"
  description = "Name for the Issuer for MinIO"
}

variable "minio_tenant_certificate_name" {
  default     = "minio-certmanager-cert"
  description = "Name for the certificate for MinIO Tenant"
}

variable "kubeconfig_path" {
  default     = "~/.kube/config"
  description = "KubeConfig Path to be used for KubeCTL commands"
}
