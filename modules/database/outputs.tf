
output "database_endpoint" {
  description = "Database endpoint"
  value       = aws_db_instance.database.endpoint
}

output "database_port" {
  description = "Database port"
  value       = aws_db_instance.database.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.database.db_name
}

output "database_username" {
  description = "Database username"
  value       = aws_db_instance.database.username
  sensitive   = true
}

output "database_security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.database.id
}