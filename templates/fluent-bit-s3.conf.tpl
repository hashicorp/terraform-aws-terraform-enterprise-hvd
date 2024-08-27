[OUTPUT]
    Name                         s3
    Match                        *
    region                       ${aws_region}
    bucket                       ${s3_log_fwd_bucket_name}
    total_file_size              100M
    s3_key_format                /\$TAG/%Y/%m/%d/%H/%M/%S/\$UUID.gz
    s3_key_format_tag_delimiters .-
