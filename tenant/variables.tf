variable "namespace" {
  default     = "minio"
  description = "Namespace to be used for deploying MinIO Tenant and related resources."
}

variable "service_account_name" {
  default     = "minio-service-account"
  description = "Service Account name for MinIO Tenant"
}

variable "role_name" {
  default     = "minio-secret-reader"
  description = "Role name for MinIO Tenant"
}

variable "role_binding_name" {
  default     = "minio-role-binding"
  description = "Role binding name for MinIO Tenant"
}

variable "bucket_names" {
  default = [
    {
      "name" = "photoatom"
    },
    {
      "name" = "postgres"
    },
  ]
  description = "MinIO Buckets to be created"
}

variable "cluster_issuer_name" {
  default     = "photoatom-issuer"
  description = "Name for the Cluster Issuer"
}

variable "photoatom_domain" {
  description = "Domain to be used for Ingress"
  default     = ""
  type        = string
}

variable "storage_configuration_name" {
  default     = "minio-storage-configuration"
  description = "Name for the storage configuration secret"
}

variable "photoatom_user_name" {
  default     = "photoatom-user"
  description = "Name for the photoatom user secret"
}

variable "postgres_user_name" {
  default     = "postgres-user"
  description = "Name for the PostgreSQL user secret"
}

variable "host_name" {
  default     = "storage"
  description = "Host name to be used with MinIO Tenant Ingress"
}
