# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data "aws_route53_zone" "tfe" {
  count = var.create_route53_tfe_dns_record && var.route53_tfe_hosted_zone_name != null ? 1 : 0

  name         = var.route53_tfe_hosted_zone_name
  private_zone = var.route53_tfe_hosted_zone_is_private
}

resource "aws_route53_record" "alias_record" {
  count = var.route53_tfe_hosted_zone_name != null && var.create_route53_tfe_dns_record ? 1 : 0

  name    = var.tfe_fqdn
  zone_id = data.aws_route53_zone.tfe[0].zone_id
  type    = "A"

  alias {
    name                   = var.lb_type == "alb" ? aws_lb.alb[0].dns_name : aws_lb.nlb[0].dns_name
    zone_id                = var.lb_type == "alb" ? aws_lb.alb[0].zone_id : aws_lb.nlb[0].zone_id
    evaluate_target_health = true
  }
}