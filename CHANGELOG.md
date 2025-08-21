# Changes on Terraform Apply

## update in-place
- security group rule descriptions

## add / destroy
- aws_route53_record.alias_record[0] (changed resource address name in `route53.tf`)

expected:
```
│ Error: creating Route53 Record: operation error Route 53: ChangeResourceRecordSets, https response error StatusCode: 400, RequestID: 984dc72c-a50d-4aab-ba85-5e4a6d3efc33, InvalidChangeBatch: [Tried to create resource record set [name='tfeaws.abasista.sbx.hashidemos.io.', type='A'] but it already exists]
│ 
│   with module.tfe.aws_route53_record.tfe_alias_record_primary[0],
│   on ../../route53.tf line 14, in resource "aws_route53_record" "tfe_alias_record_primary":
│   14: resource "aws_route53_record" "tfe_alias_record_primary" {
│ 
```

Just run Terraform again. It starts trying to create the new record before the old is fully destroyed.