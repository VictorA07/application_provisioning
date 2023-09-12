output "PublicIP_of_webserver" {
    value = aws_instance.webserver.public_ip
}

output "cloudfront_domain" {
    value = aws_cloudfront_distribution.cap-cldfront.domain_name
}

output "database" {
    value = aws_db_instance.capdb.endpoint
}