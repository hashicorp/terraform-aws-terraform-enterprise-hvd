# TFE configuration settings

In order to bootstrap and automate the TFE install, the [tfe_user_data.sh](https://github.com/hashicorp/terraform-aws-terraform-enterprise-hvd/blob/0.2.0/templates/tfe_user_data.sh.tpl) (cloud-init) script dynamically generates a `docker-compose.yaml` file containing all of the TFE configuration settings required to start and run the application. Some of these configuration settings values are derived from interpolated values from other resources that this module creates, others are derived from module input variable values, and several are automatically computed by this module.

Since the TFE installation/configuration is managed as code in this way, and the persistent data is external to the compute, you can view your TFE EC2 instance(s) as stateless, ephemeral, and immutable. If you need to add, modify, or update a configuration setting, you should do so in the Terraform code managing your TFE deployment. You should not update or modify settings in-place on your running TFE EC2 instance(s), unless it is to temporarily test or troubleshoot something prior to making a code change.

## Configuration settings reference

The [Terraform Enterprise Flexible Deployment Options configuration reference](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/configuration) page contains all of the available settings, their descriptions, and their default values. If you would like to configure one of these settings for your TFE deployment with a non-default value, then find the corresponding variable in the [variables.tf](https://github.com/hashicorp/terraform-aws-terraform-enterprise-hvd/blob/0.2.0/variables.tf) file of this module. You can specify the module input and desired value within your TFE module block.

## Where to look in the code

Within the [compute.tf](https://github.com/hashicorp/terraform-aws-terraform-enterprise-hvd/blob/0.2.0/compute.tf) file, you will see a `locals` block with a map inside of it called `user_data_args`. Almost all of the TFE configuration settings are passed from here as arguments into the [tfe_user_data.sh](https://github.com/hashicorp/terraform-aws-terraform-enterprise-hvd/blob/0.2.0/templates/tfe_user_data.sh.tpl) (cloud-init) script.

Within the [tfe_user_data.sh](https://github.com/hashicorp/terraform-aws-terraform-enterprise-hvd/blob/0.2.0/templates/tfe_user_data.sh.tpl) script there is a function named `generate_tfe_docker_compose_config()` that is responsible for receiving all of those inputs and dynamically generating the `docker-compose.yaml` file. After a successful install process, this file can be found in `/etc/tfe/docker-compose.yaml` on your TFE EC2 instance(s).

## Procedure

1. Determine which [configuration setting](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/configuration) you would like to add/modify/update.

1. Find the corresponding variable in the [variables.tf](https://github.com/hashicorp/terraform-aws-terraform-enterprise-hvd/blob/0.2.0/variables.tf) file.

1. Specify the input within your TFE module block. For example, if you want to modify the `TFE_CAPACITY_CONCURRENCY` setting to a value different from the default value of `10`:

    ```hcl
    module "tfe" {
      ...
      
      tfe_capacity_concurrency = var.tfe_capacity_concurrency
      ...
    }
    ```

    >📝 Note: If you would prefer to hard code the input value on the right side of the equals side and not use a variable, then you can do so and skip step 4.

1. Verify the corresponding variable definition exists in your own `variables.tf` file. If it is not in there, then add it. Then, update your `terraform.tfvars` file with the desired input variable value.

1. From within the Terraform directory managing your TFE deployment, run `terraform apply` to update the TFE EC2 launch template.

1. During a maintenance window, terminate the running TFE EC2 instance(s) which will trigger the autoscaling group to spawn new instance(s) from the latest version of the TFE EC2 launch template. This process will effectively re-install TFE on the new instance(s), including the updated configuration settings values within the installation configuration.
