#------------------------------------------------------------------------------
# TFE URLs
#------------------------------------------------------------------------------
output "tfe_url" {
  value       = "https://${var.tfe_fqdn}"
  description = "URL to access TFE application based on value of `tfe_fqdn` input."
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
