output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.app.public_ip
}

output "private_ip" {
  description = "EC2 private IP"
  value       = aws_instance.app.private_ip
}

output "instance_arn" {
  description = "EC2 instance ARN"
  value       = aws_instance.app.arn
}
