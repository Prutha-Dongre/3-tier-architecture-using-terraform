output "public-ip-of-proxy-server" {
  value = aws_instance.public-server.public_ip
}

output "private-ip-of-app-server" {
  value = aws_instance.private-server-1.private_ip
}

output "public-ip-of-db-server" {
  value = aws_instance.private-server-2.private_ip
}

output "rds-endpoint" {
  value = aws_db_instance.three-tier-rds.endpoint
}