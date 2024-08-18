# TFE Certificate Rotation

One of the required prerequisites to deploying this module is storing base64-encoded strings of your TFE TLS certificate and private key files in PEM format as plaintext secrets within AWS Secrets Manager for bootstrapping automation purposes. The TFE EC2 cloud-init (user_data) script is designed to retrieve the latest value of these secrets every time it runs. Therefore, the process for updating TFE's TLS certificates are to update the values of the corresponding secrets in AWS Secrets Manager, and then to replace the running EC2 instance(s) within the autoscaling group such that when the new instance(s) spawn and re-install TFE, they pick up the new certs. See the section below for detailed steps.

## Secrets

| Certificate file    | Module input variable        |
|---------------------|------------------------------|
| TFE TLS certificate | `tfe_tls_cert_secret_arn`    |
| TFE TLS private key | `tfe_tls_privkey_secret_arn` |

## Procedure

Follow these steps to rotate the certificates for your TFE instance.

1. Obtain your new TFE TLS certificate file and private key file, both in PEM format.

2. Update the values of the existing secrets in AWS Secrets Manager (`tfe_tls_cert_secret_arn` and `tfe_tls_privkey_secret_arn`, respectively). If you need assistance base64-encoding the files into strings prior to updating the secrets, see the examples below:

    On Linux (bash):
    ```sh
    cat new_tfe_cert.pem | base64 -w 0
    cat new_tfe_privkey.pem | base64 -w 0
    ```

   On macOS (terminal):
   ```sh
   cat new_tfe_cert.pem | base64
   cat new_tfe_privkey.pem | base64
   ```

   On Windows (PowerShell):
   ```powershell
   function ConvertTo-Base64 {
    param (
        [Parameter(Mandatory=$true)]
        [string]$InputString
    )
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $EncodedString = [Convert]::ToBase64String($Bytes)
    return $EncodedString
   }

   Get-Content new_tfe_cert.pem -Raw | ConvertTo-Base64 -Width 0
   Get-Content new_tfe_privkey.pem -Raw | ConvertTo-Base64 -Width 0
   ```

    > **Note:**
    > When you update the value of an AWS Secrets Manager secret, the secret ARN should not change, so **no action should be needed** in terms of updating any input variable values. If the secret ARNs _were_ to change due to other circumstances, you would need to update the following input variable values with the new ARNs, and subsequently run `terraform apply` to update the TFE EC2 launch template:
   >
    >```hcl
    >tfe_tls_cert_secret_arn    = "<new-tfe-tls-cert-secret-arn>"
    >tfe_tls_privkey_secret_arn = "<new-tfe-tls-privkey-secret-arn>"
    >```

3. During a maintenance window, terminate the running TFE EC2 instance(s) which will trigger the autoscaling group to spawn new instance(s) from the latest version of the TFE EC2 launch template. This process will effectively re-install TFE on the new instance(s), including the retrieval of the latest certificates from the AWS Secrets Manager secrets.