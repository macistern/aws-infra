output "application_url" {
  description = "Public URL of the application load balancer."
  value       = module.web_app.application_url
}

output "vpc_id" {
  description = "ID of the project VPC."
  value       = module.network.vpc_id
}
