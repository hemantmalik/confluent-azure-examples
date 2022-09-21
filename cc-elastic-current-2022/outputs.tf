output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${confluent_environment.tf-cc-azure.id}
  Kafka Cluster ID: ${confluent_kafka_cluster.azure-cluster-1.id}
  Service Account API Key: ${confluent_api_key.app-manager-kafka-api-key.id}
  Service Account API Secret: ${confluent_api_key.app-manager-kafka-api-key.secret}
  EOT
  
  sensitive = true
}