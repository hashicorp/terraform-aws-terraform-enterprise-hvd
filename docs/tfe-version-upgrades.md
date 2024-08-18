# TFE Version Upgrades

TFE follows a monthly release cadence. See the [Terraform Enterprise Releases](https://developer.hashicorp.com/terraform/enterprise/releases) page for full details on the releases. Since we have bootstrapped and automated the TFE deployment and the TFE application data is decoupled from the compute (EC2) layer, the EC2 instance(s) are stateless, ephemeral, and are treated as immutable. Therefore, the process of upgrading your TFE instance to a new version involves updating your Terraform code managing your TFE deployment to reflect the new version, applying the change via Terraform to update the TFE EC2 launch template, and then replacing running EC2 instance(s) within the autoscaling group. The steps below in the [Upgrade Procedure](#upgrade-procedure) section should only be followed during a maintenace window such that no in-flight Terraform runs are disrupted.

This module includes an input variable named `tfe_image_tag` that dicates which version of TFE is deployed.

## Procedure

1. Determine your desired version of TFE from the [Terraform Enterprise Releases](https://developer.hashicorp.com/terraform/enterprise/releases) page. The value that you need will be in the **Version** column of the table that is displayed. Ensure you are on the correct tab of the table based on the container platform you have deployed your TFE instance with (Kubernetes/Docker/Podman).

2. During a maintenance window, connect to one of your existing TFE EC2 instances and gracefully drain the node(s) from being able to execute any new Terraform runs.
   
   Access the TFE command line (`tfectl`) with Docker:
   ```sh
   sudo docker exec -it <tfe-container-name> bash
   ```

   Access the TFE command line (`tfectl`) with Podman:
   ```sh
   sudo podman exec -it <tfe-container-name> bash
   ```

   Gracefully stop work on all nodes:
   ```sh
   tfectl node drain --all
   ```

   For more details on the above commands, see the following documentation:
    - [Access the TFE Command Line](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/admin/admin-cli/cli-access)
    - [Gracefully Stop Work on a Node](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/admin/admin-cli/admin-cli#gracefully-stop-work-on-a-node)

3. Generate a backup of your RDS Aurora PostgreSQL database.

4. Update the value of the `tfe_image_tag` input variable within your `terraform.tfvars` file to the desired TFE version.
   ```hcl
   tfe_image_tag = "v202407-1"
    ```

5. From within the directory managing your TFE deployment, run `terraform apply` to update the TFE EC2 launch template.

6. Terminate the running TFE EC2 instance(s) which will trigger the autoscaling group to spawn new instance(s) from the latest version of the TFE EC2 launch template. This process will effectively re-install TFE on the new EC2 instance(s) that the autoscaling group will create to the version you specified in step 4 (new value of `tfe_image_tag`).