#------------------------------------------------------------------------------
# Redis password - AWS Secrets Manager secret lookup
#------------------------------------------------------------------------------
data "aws_secretsmanager_secret_version" "tfe_redis_password" {
  count = var.tfe_operational_mode == "active-active" && var.tfe_redis_password_secret_arn != null ? 1 : 0

  secret_id     = var.tfe_redis_password_secret_arn
  version_stage = "AWSCURRENT"
}

#------------------------------------------------------------------------------
# Redis (ElastiCache) subnet group
#------------------------------------------------------------------------------
resource "aws_elasticache_subnet_group" "tfe" {
  count = var.tfe_operational_mode == "active-active" ? 1 : 0

  name       = "${var.friendly_name_prefix}-tfe-redis-subnet-group"
  subnet_ids = var.redis_subnet_ids
}

#------------------------------------------------------------------------------
# Redis (ElastiCache) cluster
#------------------------------------------------------------------------------
resource "aws_elasticache_replication_group" "redis_cluster" {
  count = var.tfe_operational_mode == "active-active" ? 1 : 0

  engine                     = "redis"
  replication_group_id       = "${var.friendly_name_prefix}-tfe-redis-cluster"
  description                = "External Redis cluster for TFE Active/Active operational mode."
  engine_version             = var.redis_engine_version
  port                       = var.redis_port
  parameter_group_name       = var.redis_parameter_group_name
  node_type                  = var.redis_node_type
  num_cache_clusters         = length(var.redis_subnet_ids)
  multi_az_enabled           = var.redis_multi_az_enabled
  automatic_failover_enabled = var.redis_automatic_failover_enabled
  subnet_group_name          = aws_elasticache_subnet_group.tfe[0].name
  security_group_ids         = [aws_security_group.redis_allow_ingress[0].id]
  at_rest_encryption_enabled = var.redis_at_rest_encryption_enabled
  kms_key_id                 = var.redis_kms_key_arn
  transit_encryption_enabled = var.redis_transit_encryption_enabled
  auth_token                 = var.tfe_redis_password_secret_arn != null ? data.aws_secretsmanager_secret_version.tfe_redis_password[0].secret_string : null
  snapshot_retention_limit   = 0
  apply_immediately          = var.redis_apply_immediately
  auto_minor_version_upgrade = var.redis_auto_minor_version_upgrade

  tags = merge({ "Name" = "${var.friendly_name_prefix}-tfe-redis" }, var.common_tags)
}

#------------------------------------------------------------------------------
# Redis security group
#------------------------------------------------------------------------------
resource "aws_security_group" "redis_allow_ingress" {
  count = var.tfe_operational_mode == "active-active" ? 1 : 0

  name   = "${var.friendly_name_prefix}-tfe-redis-allow-ingress"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-tfe-redis-allow-ingress" }, var.common_tags)
}

resource "aws_security_group_rule" "redis_allow_ingress_from_ec2" {
  count = var.tfe_operational_mode == "active-active" ? 1 : 0

  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_allow_ingress.id
  description              = "Allow TCP/6379 (Redis) inbound to Redis cluster from TFE EC2 instances."

  security_group_id = aws_security_group.redis_allow_ingress[0].id
}
