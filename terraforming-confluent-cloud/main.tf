terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "0.11.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

resource "confluent_environment_v2" "tf-cc-azure" {
  display_name = "tf-cc-azure"
}

# Update the config to use a cloud provider and region of your choice.
# https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_kafka_cluster_v2
resource "confluent_kafka_cluster_v2" "azure-cluster-1" {
  display_name = "azure-cluster-1"
  availability = "SINGLE_ZONE"
  cloud        = "AZURE"
  region       = "eastus"
  basic {}
  environment {
    id = confluent_environment_v2.tf-cc-azure.id
  }
}