# Example Scenario - Podman | RHEL | Internal Network Load Balancer (NLB)

| Configuration               | Value                        |
|-----------------------------|------------------------------|
| Operational mode            | `active-active`              |
| Container runtime           | `podman`                     |
| Operating system            | `rhel` (major version 9)     |
| Load balancer type          | `nlb` (TCP/Layer 4)          |
| Load balancer scheme        | `internal` (private)         |
| Log forwarding destination  | `s3`                         |