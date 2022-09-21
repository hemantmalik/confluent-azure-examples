# Declarative Data Services - Terraforming Confluent Cloud & Elastic Cloud on Azure

Confluent and Elastic both provide declarative patterns for customers to stand up services using their technologies. In this demo, we will show you how to create a Terraform project that will provision Confluent Cloud and Elastic Cloud on Microsoft Azure.

This repository provides a quick demonstration of the Terraform providers for both partners in one. This Terraformed environment can be used as a foundation for other demos.

## Prerequisites

1. A Confluent Cloud account. If you do not have a Confluent Cloud account, [create one here](https://www.confluent.io/confluent-cloud/tryfree/).
2. Terraform (0.13+) installed:
    * To ensure you're using the acceptable version of Terraform you may run the following command:

        ```bash
        terraform version
        ```

        Your output should resemble:

        ```bash
        Terraform v0.13.0 # any version >= v0.13.0 is OK
        ...
        ```

3. Confluent Cloud requires API keys to manage access and authentication to different parts of the service. An API key consists of a key and a secret. You can create and manage API keys by using either the [Confluent Cloud CLI](https://docs.confluent.io/ccloud-cli/current/index.html) or the [Confluent Cloud Console](https://confluent.cloud/). Learn more about Confluent Cloud API Key access [here](https://docs.confluent.io/cloud/current/client-apps/api-keys.html#ccloud-api-keys).
   1. Open the [Confluent Cloud Console](https://confluent.cloud/settings/api-keys/create) and click **Granular access** tab, and then click **Next**.
   2. Click **Create a new one to create** tab. Enter the new service account name (`tf_runner`), then click **Next**
   3. The Cloud API key and secret are generated for the `tf_runner` service account. Save your Cloud API key and secret in a secure location. You will need this API key and secret **to use the Confluent Terraform Provider**.
   4. [Assign](https://confluent.cloud/settings/org/assignments) the `OrganizationAdmin` role to the `tf_runner` service account by following [this guide](https://docs.confluent.io/cloud/current/access-management/access-control/cloud-rbac.html#add-a-role-binding-for-a-user-or-service-account).

## Environment & Cluster Creation

1. Download and install the providers defined in the configuration:

    ```bash
    terraform init
    ```

2. Use the saved Cloud API Key of the `tf_runner` service account to set values to the `confluent_cloud_api_key` and `confluent_cloud_api_secret` input variables [using environment variables](https://www.terraform.io/language/values/variables#environment-variables):

    ```bash
    export TF_VAR_confluent_cloud_api_key="<cloud_api_key>"
    export TF_VAR_confluent_cloud_api_secret="<cloud_api_secret>"
    ```

3. Ensure the configuration is syntactically valid and internally consistent:

    ```bash
    terraform validate
    ```

4. Create a Terraform plan:

    ```bash
    terraform plan -out=cc-elastic-azure.tfplan
    ```

5. Apply the configuration:

    ```bash
    terraform apply "cc-elastic-azure.tfplan"
    ```

6. You have now created a Confluent Cloud environment and cluster using Terraform running on Azure! Visit the [Confluent Cloud Console](https://confluent.cloud/environments) or use the [Confluent CLI v2](https://docs.confluent.io/confluent-cli/current/migrate.html#directly-install-confluent-cli-v2-x) to see the resources you provisioned.

## Create Topics

To create the two required topics, add the following block of code to the bottom of the `main.tf` file and re-run the `plan` and `apply` steps.

   ```bash
   // Creating two topics: pageviews & users
   resource "confluent_kafka_topic" "pageviews" {
     kafka_cluster {
       id = confluent_kafka_cluster.azure-cluster-1.id
     }
     topic_name    = "pageviews"
     rest_endpoint = confluent_kafka_cluster.azure-cluster-1.rest_endpoint
     credentials {
       key    = confluent_api_key.app-manager-kafka-api-key.id
       secret = confluent_api_key.app-manager-kafka-api-key.secret
     }
   }

   resource "confluent_kafka_topic" "users" {
     kafka_cluster {
       id = confluent_kafka_cluster.azure-cluster-1.id
     }
     topic_name    = "users"
     rest_endpoint = confluent_kafka_cluster.azure-cluster-1.rest_endpoint
     credentials {
       key    = confluent_api_key.app-manager-kafka-api-key.id
       secret = confluent_api_key.app-manager-kafka-api-key.secret
     }
   }
   ```

## Create the Elastic Cloud deployment

## License

Copyright 2022 Confluent Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License
