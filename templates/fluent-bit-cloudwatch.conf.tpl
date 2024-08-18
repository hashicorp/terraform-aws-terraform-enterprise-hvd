[OUTPUT]
    Name               cloudwatch_logs
    Match              *
    region             ${aws_region}
    log_group_name     ${cloudwatch_log_group_name}
    log_stream_prefix  tfe-logs-prefix-