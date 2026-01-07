# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# TFE URLs
#------------------------------------------------------------------------------
output "tfe_url" {
  value       = "https://${var.tfe_fqdn}"
  description = "URL to access TFE application based on value of `tfe_fqdn` input."
}

output "tfe_create_initial_admin_user_url" {
  value       = "https://${var.tfe_fqdn}/admin/account/new?token=<IACT_TOKEN>"
  description = "URL to create TFE initial admin user."
}

output "lb_dns_name" {
  value       = var.lb_type == "alb" ? aws_lb.alb[0].dns_name : aws_lb.nlb[0].dns_name
  description = "DNS name of the Load Balancer."
}

#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------
output "tfe_database_host" {
  value       = "${aws_rds_cluster.tfe.endpoint}:5432"
  description = "PostgreSQL server endpoint in the format that TFE will connect to."
}

output "rds_aurora_global_cluster_id" {
  value       = try(aws_rds_global_cluster.tfe[0].id, null)
  description = "RDS Aurora global database cluster identifier."
}

output "rds_aurora_cluster_arn" {
  value       = aws_rds_cluster.tfe.arn
  description = "ARN of RDS Aurora database cluster."
  depends_on  = [aws_rds_cluster_instance.tfe]
}

output "rds_aurora_cluster_members" {
  value       = aws_rds_cluster.tfe.cluster_members
  description = "List of instances that are part of this RDS Aurora database cluster."
  depends_on  = [aws_rds_cluster_instance.tfe]
}

output "rds_aurora_cluster_endpoint" {
  value       = aws_rds_cluster.tfe.endpoint
  description = "RDS Aurora database cluster endpoint."
}

#------------------------------------------------------------------------------
# Object storage
#------------------------------------------------------------------------------
output "s3_bucket_name" {
  value       = aws_s3_bucket.tfe.id
  description = "Name of TFE S3 bucket."
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.tfe.arn
  description = "ARN of TFE S3 bucket."
}

output "s3_crr_iam_role_arn" {
  value       = try(aws_iam_role.s3_crr[0].arn, null)
  description = "ARN of S3 cross-region replication IAM role."
}

#------------------------------------------------------------------------------
# Redis
#------------------------------------------------------------------------------
output "elasticache_replication_group_arn" {
  value       = try(aws_elasticache_replication_group.redis_cluster[0].arn, null)
  description = "ARN of ElastiCache Replication Group (Redis) cluster."
}

output "elasticache_replication_group_id" {
  value       = try(aws_elasticache_replication_group.redis_cluster[0].id, null)
  description = "ID of ElastiCache Replication Group (Redis) cluster."
}

output "elasticache_replication_group_primary_endpoint_address" {
  value       = try(aws_elasticache_replication_group.redis_cluster[0].primary_endpoint_address, null)
  description = "Primary endpoint address of ElastiCache Replication Group (Redis) cluster."
}

#------------------------------------------------------------------------------
# Admin Console
#------------------------------------------------------------------------------
output "tfe_admin_console_enabled" {
  value       = var.tfe_admin_console_enabled
  description = "Boolean indicating whether the TFE Admin Console is enabled."
}

output "tfe_admin_console_port" {
  value       = var.tfe_admin_console_port
  description = "Port the TFE Admin Console listens on."
}

output "tfe_admin_console_url_pattern" {
  value       = var.tfe_admin_console_enabled ? "https://<EC2_INSTANCE_IP>:${var.tfe_admin_console_port}" : null
  description = "URL pattern to access the TFE Admin Console. Replace <EC2_INSTANCE_IP> with the actual EC2 instance IP address."
}
