# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

#------------------------------------------------------------------------------
# Common
#------------------------------------------------------------------------------
locals {
  lb_name_suffix = var.lb_is_internal ? "internal" : "external"
}

#------------------------------------------------------------------------------
# Network load balancer (NLB) - Primary
#------------------------------------------------------------------------------
resource "aws_lb" "nlb" {
  count = var.lb_type == "nlb" ? 1 : 0

  name               = "${var.friendly_name_prefix}-tfe-nlb-${local.lb_name_suffix}"
  load_balancer_type = "network"
  internal           = var.lb_is_internal
  subnets            = var.lb_subnet_ids

  security_groups = [
    aws_security_group.lb_allow_ingress.id,
    aws_security_group.lb_allow_egress.id
  ]

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-nlb-${local.lb_name_suffix}" },
    var.common_tags
  )
}

resource "aws_lb_listener" "lb_nlb_443" {
  count = var.lb_type == "nlb" ? 1 : 0

  load_balancer_arn = aws_lb.nlb[0].arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_443[0].arn
  }
}

resource "aws_lb_target_group" "nlb_443" {
  count = var.lb_type == "nlb" ? 1 : 0

  name     = "${var.friendly_name_prefix}-tfe-nlb-tg-443"
  protocol = "TCP"
  port     = 443
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTPS"
    path                = "/_health_check"
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
    { "Name" = "${var.friendly_name_prefix}-tfe-nlb-tg-443" },
    { "Description" = "Load balancer target group for TFE application traffic." },
    var.common_tags
  )
}

#------------------------------------------------------------------------------
# Application load balancer (ALB) - Primary
#------------------------------------------------------------------------------
resource "aws_lb" "alb" {
  count = var.lb_type == "alb" ? 1 : 0

  name               = "${var.friendly_name_prefix}-tfe-alb-${local.lb_name_suffix}"
  internal           = var.lb_is_internal
  load_balancer_type = "application"
  subnets            = var.lb_subnet_ids

  security_groups = [
    aws_security_group.lb_allow_ingress.id,
    aws_security_group.lb_allow_egress.id
  ]

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-alb-${local.lb_name_suffix}" },
    var.common_tags
  )
}

resource "aws_lb_listener" "alb_443" {
  count = var.lb_type == "alb" ? 1 : 0

  load_balancer_arn = aws_lb.alb[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.tfe_alb_tls_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_443[0].arn
  }
}

resource "aws_lb_target_group" "alb_443" {
  count = var.lb_type == "alb" ? 1 : 0

  name     = "${var.friendly_name_prefix}-tfe-alb-tg-443"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTPS"
    path                = "/_health_check"
    healthy_threshold   = 2
    unhealthy_threshold = 7
    timeout             = 5
    interval            = 30
    matcher             = 200
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-alb-tg-443" },
    { "Description" = "Primary load balancer target group for TFE application traffic." },
    var.common_tags
  )
}

#------------------------------------------------------------------------------
# Network load balancer (NLB) - Secondary
#------------------------------------------------------------------------------
resource "aws_lb" "nlb_secondary" {
  count = var.tfe_fqdn_secondary != null && var.lb_type_secondary == "nlb" ? 1 : 0

  name               = "${var.friendly_name_prefix}-tfe-nlb-sec-${local.lb_name_suffix}"
  load_balancer_type = "network"
  internal           = var.lb_secondary_is_internal
  subnets            = var.lb_secondary_subnet_ids

  security_groups = [
    aws_security_group.lb_secondary_allow_ingress[0].id,
    aws_security_group.lb_secondary_allow_egress[0].id
  ]

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-nlb-sec-${local.lb_name_suffix}" },
    var.common_tags
  )
}

resource "aws_lb_listener" "nlb_443_secondary" {
  count = var.tfe_fqdn_secondary != null && var.lb_type_secondary == "nlb" ? 1 : 0

  load_balancer_arn = aws_lb.nlb_secondary[0].arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_443_secondary[0].arn
  }
}

resource "aws_lb_target_group" "nlb_443_secondary" {
  count = var.tfe_fqdn_secondary != null && var.lb_type_secondary == "nlb" ? 1 : 0

  name     = "${var.friendly_name_prefix}-tfe-nlb-sec-tg-443"
  protocol = "TCP"
  port     = 443
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTPS"
    path                = "/_health_check"
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
    { "Name" = "${var.friendly_name_prefix}-tfe-nlb-sec-tg-443" },
    { "Description" = "Secondary load balancer target group for TFE application traffic." },
    var.common_tags
  )
}

#------------------------------------------------------------------------------
# Application load balancer (ALB) - Secondary
#------------------------------------------------------------------------------
resource "aws_lb" "alb_secondary" {
  count = var.tfe_fqdn_secondary != null && var.lb_type_secondary == "alb" ? 1 : 0

  name               = "${var.friendly_name_prefix}-tfe-alb-sec-${local.lb_name_suffix}"
  internal           = var.lb_is_internal
  load_balancer_type = "application"
  subnets            = var.lb_subnet_ids

  security_groups = [
    aws_security_group.lb_secondary_allow_ingress[0].id,
    aws_security_group.lb_secondary_allow_egress[0].id
  ]

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-alb-sec-${local.lb_name_suffix}" },
    var.common_tags
  )
}

resource "aws_lb_listener" "alb_443_secondary" {
  count = var.tfe_fqdn_secondary != null && var.lb_type_secondary == "alb" ? 1 : 0

  load_balancer_arn = aws_lb.alb_secondary[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.tfe_alb_secondary_tls_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_443_secondary[0].arn
  }
}

resource "aws_lb_target_group" "alb_443_secondary" {
  count = var.tfe_fqdn_secondary != null && var.lb_type_secondary == "alb" ? 1 : 0

  name     = "${var.friendly_name_prefix}-tfe-alb-sec-tg-443"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "HTTPS"
    path                = "/_health_check"
    healthy_threshold   = 2
    unhealthy_threshold = 7
    timeout             = 5
    interval            = 30
    matcher             = 200
  }

  tags = merge(
    { "Name" = "${var.friendly_name_prefix}-tfe-alb-sec-tg-443" },
    { "Description" = "Secondary load balancer target group for TFE application traffic." },
    var.common_tags
  )
}

#------------------------------------------------------------------------------
# Security groups - Primary load balancer
#------------------------------------------------------------------------------
resource "aws_security_group" "lb_allow_ingress" {
  name   = "${var.friendly_name_prefix}-tfe-lb-allow-ingress"
  vpc_id = var.vpc_id

  tags = merge({ "Name" = "${var.friendly_name_prefix}-tfe-lb-allow-ingress" }, var.common_tags)
}

resource "aws_security_group_rule" "lb_allow_ingress_tfe_https_from_cidr" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_ingress_tfe_lb_443
  description = "Allow TCP/443 (HTTPS) inbound to primary TFE load balancer from specified CIDR ranges."

  security_group_id = aws_security_group.lb_allow_ingress.id
}

resource "aws_security_group_rule" "lb_allow_ingress_tfe_https_from_ec2" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_allow_ingress.id
  description              = "Allow TCP/443 (HTTPS) inbound to primary TFE load balancer from TFE EC2 security group."

  security_group_id = aws_security_group.lb_allow_ingress.id
}

resource "aws_security_group" "lb_allow_egress" {
  name   = "${var.friendly_name_prefix}-tfe-lb-allow-egress"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-tfe-lb-allow-egress" }, var.common_tags)
}

resource "aws_security_group_rule" "lb_allow_egress_all" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all traffic outbound from the primary TFE load balancer."

  security_group_id = aws_security_group.lb_allow_egress.id
}

#------------------------------------------------------------------------------
# Security groups - Secondary load balancer
#------------------------------------------------------------------------------
resource "aws_security_group" "lb_secondary_allow_ingress" {
  count = var.tfe_fqdn_secondary != null ? 1 : 0

  name   = "${var.friendly_name_prefix}-tfe-lb-secondary-allow-ingress"
  vpc_id = var.vpc_id

  tags = merge({ "Name" = "${var.friendly_name_prefix}-tfe-lb-secondary-allow-ingress" }, var.common_tags)
}

resource "aws_security_group_rule" "lb_secondary_allow_ingress_tfe_https_from_cidr" {
  count = var.tfe_fqdn_secondary != null && var.cidr_allow_ingress_tfe_lb_secondary_443 != null ? 1 : 0

  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = var.cidr_allow_ingress_tfe_lb_secondary_443
  description = "Allow TCP/443 (HTTPS) inbound to secondary TFE load balancer from specified CIDR ranges."

  security_group_id = aws_security_group.lb_secondary_allow_ingress[0].id
}

resource "aws_security_group_rule" "lb_secondary_allow_ingress_tfe_https_from_ec2" {
  count = var.tfe_fqdn_secondary != null ? 1 : 0

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ec2_allow_ingress.id
  description              = "Allow TCP/443 (HTTPS) inbound to secondary TFE load balancer from TFE EC2 security group."

  security_group_id = aws_security_group.lb_secondary_allow_ingress[0].id
}

resource "aws_security_group" "lb_secondary_allow_egress" {
  count = var.tfe_fqdn_secondary != null ? 1 : 0

  name   = "${var.friendly_name_prefix}-tfe-lb-secondary-allow-egress"
  vpc_id = var.vpc_id
  tags   = merge({ "Name" = "${var.friendly_name_prefix}-tfe-lb-secondary-allow-egress" }, var.common_tags)
}

resource "aws_security_group_rule" "lb_secondary_allow_egress_all" {
  count = var.tfe_fqdn_secondary != null ? 1 : 0

  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  description = "Allow all traffic outbound from the secondary TFE load balancer."

  security_group_id = aws_security_group.lb_secondary_allow_egress[0].id
}