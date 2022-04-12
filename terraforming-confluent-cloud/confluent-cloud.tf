# Example for using Confluent Cloud https://docs.confluent.io/cloud/current/api.html
# that creates multiple resources: a service account, an environment, a basic cluster, a topic, and 2 ACLs.
# Configure Confluent Cloud provider
terraform {
  required_providers {
    confluentcloud = {
      source  = "confluentinc/confluentcloud"
      version = "0.5.0"
    }
  }
}

provider "confluentcloud" {}

resource "confluentcloud_environment" "azure-demo-env" {
  display_name = var.cc-environment-display-name
}

resource "confluentcloud_kafka_cluster" "azure-basic-cluster" {
  display_name = var.cc-cluster-display-name
  availability = var.cc-availability
  cloud = "AZURE"
  region = var.cc-region
  basic {}
  environment {
    id = confluentcloud_environment.azure-demo-env.id

  }
}