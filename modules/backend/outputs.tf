output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.backend.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.backend.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.backend.public_dns
}

output "security_group_id" {
  description = "ID of the backend security group"
  value       = aws_security_group.backend_sg.id
}

output "iam_role_arn" {
  description = "ARN of the backend IAM role"
  value       = aws_iam_role.backend_role.arn
}

output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.backend_profile.name
}

# SSH Key outputs
output "ssh_private_key_path" {
  description = "Path to the generated SSH private key"
  value       = local_file.backend_private_key.filename
}

output "ssh_key_name" {
  description = "Name of the AWS key pair"
  value       = aws_key_pair.backend_key.key_name
}

# SSH connection details
output "ssh_connection_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ${local_file.backend_private_key.filename} ec2-user@${aws_instance.backend.public_ip}"
}

output "ssh_tunnel_command" {
  description = "SSH tunnel command for database access"
  value       = "ssh -i ${local_file.backend_private_key.filename} -L 5432:${split(":", var.db_host)[0]}:${var.db_port} ec2-user@${aws_instance.backend.public_ip}"
}

# Debug outputs to verify split function
output "debug_db_host_original" {
  description = "Original db_host value"
  value       = var.db_host
}

output "debug_db_host_split" {
  description = "Split db_host result (first part)"
  value       = split(":", var.db_host)[0]
}

output "debug_db_host_split_full" {
  description = "Full split result"
  value       = split(":", var.db_host)
}