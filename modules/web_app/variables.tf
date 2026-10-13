variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the demo workload."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the application is deployed."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs used by the load balancer and application instance."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least two public subnet IDs are required for the load balancer."
  }
}
