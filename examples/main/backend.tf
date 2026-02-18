# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

# This is a placeholder for the S3 remote backend configuration.
# Uncomment and configure your own custom values in the backend block below.
# Refer to https://developer.hashicorp.com/terraform/language/settings/backends/s3 for more information.

/*
terraform {
    backend s3 {
        bucket = "<terraform-state-bucket>"
        key    = "<terraform-state-key>"
        region = "<aws-region>"
        ...
   }
}
*/