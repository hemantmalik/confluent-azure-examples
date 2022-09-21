terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.0.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

resource "confluent_environment" "cc-environment" {
  display_name = var.confluent_cloud_environment_name
}

resource "confluent_kafka_cluster" "cc-cluster-01" {
  display_name = var.confluent_cloud_cluster_name
  availability = var.confluent_cloud_cluster_availability
  cloud        = var.confluent_cloud_csp
  region       = var.confluent_cloud_csp_region
  basic {}
  environment {
    id = confluent_environment.cc-environment.id
  }
}

// Creating the 'app-manager' service account which is required in this configuration to create and work with topics.
resource "confluent_service_account" "app-manager" {
  display_name = "app-manager"
  description  = "Service account to manage Kafka cluster"
}

resource "confluent_role_binding" "app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.cc-cluster-01.rbac_crn
}

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = var.kafka_api_key_description
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.cc-cluster-01.id
    api_version = confluent_kafka_cluster.cc-cluster-01.api_version
    kind        = confluent_kafka_cluster.cc-cluster-01.kind

    environment {
      id = confluent_environment.cc-environment.id
    }
  }

  // The goal is to ensure that confluent_role_binding.app-manager-kafka-cluster-admin is created before
  // confluent_api_key.app-manager-kafka-api-key is used to create instances of
  // confluent_kafka_topic, confluent_kafka_acl resources.

  // 'depends_on' meta-argument is specified in confluent_api_key.app-manager-kafka-api-key to avoid having
  // multiple copies of this definition in the configuration which would happen if we specify it in
  // confluent_kafka_topic, confluent_kafka_acl resources instead.
  depends_on = [
    confluent_role_binding.app-manager-kafka-cluster-admin
  ]
}

// Creating two topics: pageviews & users
resource "confluent_kafka_topic" "pageviews" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc-cluster-01.id
  }
  topic_name    = "pageviews"
  rest_endpoint = confluent_kafka_cluster.cc-cluster-01.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_topic" "users" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc-cluster-01.id
  }
  topic_name    = "users"
  rest_endpoint = confluent_kafka_cluster.cc-cluster-01.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "null_resource" "create-ksql-and-schema-registry" {
  provisioner "local-exec" {
    command = "./ksql-schema.sh"
    environment = {
      ENV_ID = var.cc-env-id
      CLUSTER_ID = var.cc-cluster-id
      HTTP_ENDPOINT = var.cc-cluster-http-endpoint
    }
  }
}

// Creating the service account that will be used for Connectors
resource "confluent_service_account" "app-connectors" {
  display_name = "app-connectors"
  description  = "Connectors service account used to consume from 'users' and 'pageviews' topics of 'cc-cluster-01' Kafka cluster"
}


resource "confluent_kafka_acl" "app-connectors-describe-on-cluster" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc-cluster-01.id
  }
  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-connectors.id}"
  host          = "*"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cc-cluster-01.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connectors-write-on-pageviews-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc-cluster-01.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.pageviews.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-connectors.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cc-cluster-01.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connectors-write-on-users-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc-cluster-01.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.users.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app-connectors.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cc-cluster-01.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connectors-create-on-data-preview-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc-cluster-01.id
  }
  resource_type = "TOPIC"
  resource_name = "data-preview"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-connectors.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cc-cluster-01.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connectors-write-on-data-preview-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.cc-cluster-01.id
  }
  resource_type = "TOPIC"
  resource_name = "data-preview"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.app-connectors.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.cc-cluster-01.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

// Creating the two Datagen connectors that will populate the 'pageviews' and 'users' topics
resource "confluent_connector" "source-datagen-pageviews" {
  environment {
    id = confluent_environment.cc-environment.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.cc-cluster-01.id
  }

  config_sensitive = {}

  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "datagen_pageviews"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.app-connectors.id
    "kafka.topic"              = confluent_kafka_topic.pageviews.topic_name
    "output.data.format"       = "AVRO"
    "quickstart"               = "PAGEVIEWS"
    "max.interval"             = "500"
    "iterations"               = "1000000000"
    "tasks.max"                = "1"
  }

  depends_on = [
    confluent_kafka_acl.app-connectors-describe-on-cluster,
    confluent_kafka_acl.app-connectors-write-on-pageviews-topic,
    confluent_kafka_acl.app-connectors-create-on-data-preview-topics,
    confluent_kafka_acl.app-connectors-write-on-data-preview-topics,
    null_resource.create-ksql-and-schema-registry
  ]
}

resource "confluent_connector" "source-datagen-users" {
  environment {
    id = confluent_environment.cc-environment.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.cc-cluster-01.id
  }

  config_sensitive = {}

  config_nonsensitive = {
    "connector.class"          = "DatagenSource"
    "name"                     = "datagen_users"
    "kafka.auth.mode"          = "SERVICE_ACCOUNT"
    "kafka.service.account.id" = confluent_service_account.app-connectors.id
    "kafka.topic"              = confluent_kafka_topic.pageviews.topic_name
    "output.data.format"       = "PROTOBUF"
    "quickstart"               = "USERS"
    "max.interval"             = "2000"
    "iterations"               = "1000000000"
    "tasks.max"                = "1"
  }

  depends_on = [
    confluent_kafka_acl.app-connectors-describe-on-cluster,
    confluent_kafka_acl.app-connectors-write-on-users-topic,
    confluent_kafka_acl.app-connectors-create-on-data-preview-topics,
    confluent_kafka_acl.app-connectors-write-on-data-preview-topics,
    null_resource.create-ksql-and-schema-registry
  ]
}