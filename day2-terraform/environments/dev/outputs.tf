output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "ec2_public_ip" {
  description = "EC2 public IP"
  value       = module.ec2.public_ip
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.endpoint
}

output "alb_url" {
  description = "Application URL"
  value       = module.alb.alb_url
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i <your-key>.pem ec2-user@${module.ec2.public_ip}"
}
