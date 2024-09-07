variable "namespace" {
  default     = "minio"
  description = "Namespace to be used for deploying MinIO Tenant and related resources."
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
