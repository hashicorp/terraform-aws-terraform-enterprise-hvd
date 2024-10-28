# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# TFE URLs
#------------------------------------------------------------------------------
output "tfe_urls" {
  value = {
    tfe_url                           = module.tfe.tfe_url
    tfe_create_initial_admin_user_url = module.tfe.tfe_create_initial_admin_user_url
    tfe_lb_dns_name                   = module.tfe.lb_dns_name
  }
}

#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------
output "database" {
  value = {
    rds_global_cluster_id = module.tfe.rds_aurora_global_cluster_id
    rds_cluster_arn       = module.tfe.rds_aurora_cluster_arn
  }
}

#------------------------------------------------------------------------------
# Object storage
#------------------------------------------------------------------------------
output "object_storage" {
  value = {
    s3_bucket_name = module.tfe.s3_bucket_name
    s3_bucket_arn  = module.tfe.s3_bucket_arn
  }
}
