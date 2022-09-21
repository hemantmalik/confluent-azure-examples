variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_environment_name" {
  description = "Confluent Cloud Environment Display Name"
  type        = string
  sensitive   = false
}

variable "confluent_cloud_cluster_name" {
  description = "Confluent Cloud Cluster Display Name"
  type        = string
  sensitive   = false
}

variable "confluent_cloud_cluster_availability" {
  description = "Confluent Cloud Cluster Availability Model"
  type        = string
  sensitive   = false
}

variable "confluent_cloud_csp" {
  description = "Confluent Cloud CSP"
  type        = string
  sensitive   = false
}

variable "confluent_cloud_csp_region" {
  description = "Confluent Cloud CSP Region"
  type        = string
  sensitive   = false
}
