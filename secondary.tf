# Copyright IBM Corp. 2024, 2025
# SPDX-License-Identifier: MPL-2.0

locals {
  secondary_hostname_enabled = var.tfe_hostname_secondary != null
  secondary_nlb_enabled      = local.secondary_hostname_enabled && var.create_secondary_tfe_nlb
  secondary_lb_target_group_arns = local.secondary_nlb_enabled ? [
    aws_lb_target_group.secondary_nlb_443[0].arn
  ] : []
}

data "aws_route53_zone" "tfe_secondary" {
  count = var.create_route53_tfe_secondary_dns_record && var.route53_tfe_secondary_hosted_zone_name != null ? 1 : 0

  name         = var.route53_tfe_secondary_hosted_zone_name
  private_zone = var.route53_tfe_secondary_hosted_zone_is_private
}

resource "aws_lb" "secondary_nlb" {
  count = local.secondary_nlb_enabled ? 1 : 0

  name               = "${var.friendly_name_prefix}-tfe2-nlb-public"
  load_balancer_type = "network"
  internal           = false
  subnets            = var.secondary_lb_subnet_ids

  security_groups = [
    aws_security_group.secondary_lb_allow_ingress[0].id,
    aws_security_group.secondary_lb_allow_egress[0].id
  ]

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe2-nlb-public" },
    { "Description" = "Secondary public load balancer for Terraform Enterprise integration traffic." },
    var.common_tags
  )
}

resource "aws_lb_listener" "secondary_nlb_443" {
  count = local.secondary_nlb_enabled ? 1 : 0

  load_balancer_arn = aws_lb.secondary_nlb[0].arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.secondary_nlb_443[0].arn
  }
}

resource "aws_lb_target_group" "secondary_nlb_443" {
  count = local.secondary_nlb_enabled ? 1 : 0

  name     = "${var.friendly_name_prefix}-tfe2-nlb-tg443"
  protocol = "TCP"
  port     = 443
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTPS"
    path                = local.tfe_image_tag_gte_1 ? "/api/v1/health/readiness" : "/_health_check"
    port                = "traffic-port"
    matcher             = "200"
    healthy_threshold   = 5
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
  }

  stickiness {
    enabled = var.lb_stickiness_enabled
    type    = "source_ip"
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe2-nlb-tg443" },
    { "Description" = "Load balancer target group for TFE secondary hostname traffic." },
    var.common_tags
  )
}

resource "aws_security_group" "secondary_lb_allow_ingress" {
  count = local.secondary_nlb_enabled ? 1 : 0

  name   = "${var.friendly_name_prefix}-tfe-secondary-lb-allow-ingress"
  vpc_id = var.vpc_id

  tags = merge({ "Name" = "${var.friendly_name_prefix}-tfe-secondary-lb-allow-ingress" }, var.common_tags)
}

resource "aws_security_group_rule" "secondary_lb_allow_ingress_tfe_https_from_cidr" {
  count = local.secondary_nlb_enabled ? 1 : 0

  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_ingress_tfe_secondary_443
  description = "Allow TCP/443 (HTTPS) inbound to the secondary TFE load balancer from specified CIDR ranges."

  security_group_id = aws_security_group.secondary_lb_allow_ingress[0].id
}

resource "aws_security_group_rule" "secondary_lb_allow_ingress_tfe_https_from_ec2" {
  count = local.secondary_nlb_enabled ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_allow_ingress.id
  description              = "Allow TCP/443 (HTTPS) inbound to the secondary TFE load balancer from the TFE EC2 security group."

  security_group_id = aws_security_group.secondary_lb_allow_ingress[0].id
}

resource "aws_security_group" "secondary_lb_allow_egress" {
  count = local.secondary_nlb_enabled ? 1 : 0

  name   = "${var.friendly_name_prefix}-tfe-secondary-lb-allow-egress"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-tfe-secondary-lb-allow-egress" }, var.common_tags)
}

resource "aws_security_group_rule" "secondary_lb_allow_egress_all" {
  count = local.secondary_nlb_enabled ? 1 : 0

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all traffic outbound from the secondary TFE load balancer."

  security_group_id = aws_security_group.secondary_lb_allow_egress[0].id
}

resource "aws_security_group_rule" "ec2_allow_ingress_tfe_https_from_secondary_lb" {
  count = local.secondary_nlb_enabled ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.secondary_lb_allow_ingress[0].id
  description              = "Allow TCP/443 (HTTPS) inbound to TFE EC2 instances from the secondary TFE load balancer."

  security_group_id = aws_security_group.ec2_allow_ingress.id
}

resource "aws_route53_record" "secondary_alias_record" {
  count = var.create_route53_tfe_secondary_dns_record ? 1 : 0

  name    = var.tfe_hostname_secondary
  zone_id = data.aws_route53_zone.tfe_secondary[0].zone_id
  type    = "A"

  alias {
    name                   = aws_lb.secondary_nlb[0].dns_name
    zone_id                = aws_lb.secondary_nlb[0].zone_id
    evaluate_target_health = true
  }
}
