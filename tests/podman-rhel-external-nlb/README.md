# CI Test - Podman | RHEL | External Network Load Balancer (NLB)

PLACEHOLDER - NOT YET SUPPORTED.

This directory contains the Terraform configuration used in the `podman-rhel-external-nlb` test case for this Terraform module. The specifications are as follows:

| Parameter                   | Value                        |
|-----------------------------|------------------------------|
| Operational Mode            | `active-active`              |
| Container Runtime           | `podman`                     |
| Operating System            | `RHEL 9`                     |
| Load Balancer Type          | `nlb` (TCP/Layer 4)          |
| Load Balancer Scheme        | `external` (Internet-facing) |
| Log Forwarding Destination  | `cloudwatch`                 |