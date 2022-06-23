output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${confluent_environment_v2.tf-cc-azure.id}
  Kafka Cluster ID: ${confluent_kafka_cluster_v2.azure-cluster-1.id}
  EOT
  
  sensitive = true
}