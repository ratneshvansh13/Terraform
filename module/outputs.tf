output "vpc_id" {
  description = "VPC created by network module"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnets created by network module"
  value       = module.network.public_subnet_ids
}