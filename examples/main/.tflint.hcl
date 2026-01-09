# TFLint Config
# https://github.com/terraform-linters/tflint
#
# brew install tflint
# tflint --init
# tflint

# Config ###################################################################
# https://github.com/terraform-linters/tflint/blob/master/docs/user-guide/config.md
config {
  call_module_type = "all"
}

# Terraform ################################################################
# https://github.com/terraform-linters/tflint-ruleset-terraform/tree/v0.10.0/docs/rules

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = false
}

rule "terraform_standard_module_structure" {
  enabled = false
}

rule "terraform_unused_declarations" {
  enabled = false

  # tfc_hmac_token
}

rule "terraform_naming_convention" {
  enabled = true
}
rule "terraform_comment_syntax" {
	enabled = true
}

# AWS #####################################################################
# https://github.com/terraform-linters/tflint-ruleset-aws/blob/master/docs/rules/README.md

# plugin "aws" {
#   enabled = true
#   version = "0.44.0"
#   source  = "github.com/terraform-linters/tflint-ruleset-aws"
# }
