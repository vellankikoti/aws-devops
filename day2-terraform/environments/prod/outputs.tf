output "vpc_id" {
  value = module.vpc.vpc_id
}

output "alb_url" {
  value = module.alb.alb_url
}

output "rds_endpoint" {
  value     = module.rds.endpoint
  sensitive = true
}
