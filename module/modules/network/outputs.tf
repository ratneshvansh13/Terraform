#VPC Outputs:
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

#Subnet Outputs:
output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = values(aws_subnet.public)[*].id
}