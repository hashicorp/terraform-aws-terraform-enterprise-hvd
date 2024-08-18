#------------------------------------------------------------------------------
# TFE URLs
#------------------------------------------------------------------------------
output "tfe_url" {
  value = module.tfe.tfe_url
}

output "tfe_lb_dns_name" {
  value = module.tfe.lb_dns_name
}

#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------
output "rds_aurora_global_cluster_id" {
  value = module.tfe.rds_aurora_global_cluster_id
}

output "rds_aurora_cluster_arn" {
  value = module.tfe.rds_aurora_cluster_arn
}

output "rds_aurora_cluster_members" {
  value = module.tfe.rds_aurora_cluster_members
}

output "rds_aurora_cluster_endpoint" {
  value = module.tfe.rds_aurora_cluster_endpoint
}

#------------------------------------------------------------------------------
# Object storage
#------------------------------------------------------------------------------
output "tfe_s3_bucket_name" {
  value = module.tfe.s3_bucket_name
}
