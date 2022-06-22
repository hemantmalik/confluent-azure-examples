# Terraforming Confluent Cloud on Azure

The Confluent Terraform Provider is a plugin for Terraform that allows for the lifecycle management of Confluent resources.

This repository provides a quick template to use to create an environment and cluster running on Azure.

## Documentation

Full documentation is available on the [Terraform website](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs).

## Prerequisites

1. A Confluent Cloud account. If you do not have a Confluent Cloud account, [create one now](https://www.confluent.io/confluent-cloud/tryfree/).
2. Terraform (0.14+) installed:
    * Install Terraform version manager [tfutils/tfenv](https://github.com/tfutils/tfenv)
    * Alternatively, install the [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli#install-terraform)
    * To ensure you're using the acceptable version of Terraform you may run the following command:

        ```bash
        terraform version
        ```

        Your output should resemble:

        ```bash
        Terraform v0.14.0 # any version >= v0.14.0 is OK
        ...
        ```

3. A Confluent Cloud API Key
   1. Open the [Confluent Cloud Console](https://confluent.cloud/settings/api-keys/create) and click **Granular access** tab, and then click **Next**.
   2. Click **Create a new one to create** tab. Enter the new service account name (`tf_runner`), then click **Next**.
   3. The Cloud API key and secret are generated for the `tf_runner` service account. Save your Cloud API key and secret in a secure location. You will need this API key and secret **to use the Confluent Terraform Provider**.
   4. [Assign](https://confluent.cloud/settings/org/assignments) the `OrganizationAdmin` role to the `tf_runner` service account by following [this guide](https://docs.confluent.io/cloud/current/access-management/access-control/cloud-rbac.html#add-a-role-binding-for-a-user-or-service-account).

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
