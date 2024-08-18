# CI Test - Docker | Ubuntu | External Network Load Balancer (NLB)

This directory contains the Terraform configuration used in the `docker-ubuntu-external-nlb` test case for this Terraform module. The specifications are as follows:

| Parameter                   | Value                        |
|-----------------------------|------------------------------|
| Operational Mode            | `active-active`              |
| Container Runtime           | `docker`                     |
| Operating System            | `ubuntu`                     |
| Load Balancer Type          | `nlb` (TCP/Layer 4)          |
| Load Balancer Scheme        | `external` (Internet-facing) |
| Log Forwarding Destination  | `cloudwatch`                 |