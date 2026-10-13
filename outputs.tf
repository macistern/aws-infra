output "application_url" {
  description = "Public URL of the application load balancer."
  value       = "http://${aws_lb.application.dns_name}"
}

output "vpc_id" {
  description = "ID of the project VPC."
  value       = aws_vpc.main.id
}
