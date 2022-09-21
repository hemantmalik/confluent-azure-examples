terraform {
  required_version = ">= 0.13.0"
  
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.4.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

// Creating the Confluent Cloud Environment
resource "confluent_environment" "tf-cc-azure" {
  display_name = "bogie-current-2022-azure-demo1"
}

// Creating the Confluent Cloud Cluster
// Update the config to use a cloud provider and region of your choice.
// https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_kafka_cluster_v2
resource "confluent_kafka_cluster" "azure-cluster-1" {
  display_name = "azure-cluster-1"
  availability = "SINGLE_ZONE"
  cloud        = "AZURE"
  region       = "southcentralus"
  basic {}
  environment {
    id = confluent_environment.tf-cc-azure.id
  }
}

// Create the Service Account
resource "confluent_service_account" "app-manager" {
  display_name = "app-manager"
  description  = "Service account to manage 'inventory' Kafka cluster"
}

// Assign the Cluster Admin role to the Service Account
resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.azure-cluster-1.rbac_crn
  depends_on = [
    confluent_service_account.app-manager
  ]
}

// Create the API key for the Service Account
resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.azure-cluster-1.id
    api_version = confluent_kafka_cluster.azure-cluster-1.api_version
    kind        = confluent_kafka_cluster.azure-cluster-1.kind

    environment {
      id = confluent_environment.tf-cc-azure.id
    }
  }
}