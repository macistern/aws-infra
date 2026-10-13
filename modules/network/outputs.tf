output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets, ordered by availability zone."
  value       = [for availability_zone in sort(keys(aws_subnet.public)) : aws_subnet.public[availability_zone].id]
}
