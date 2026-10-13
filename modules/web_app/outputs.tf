output "application_url" {
  description = "Public HTTP URL of the application load balancer."
  value       = "http://${aws_lb.application.dns_name}"
}
