# modules/vpc/outputs.tf
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = local.azs
}

output "vpc_endpoints" {
  description = "VPC Endpoints information"
  value = {
    s3_endpoint_id      = var.enable_vpc_endpoints ? aws_vpc_endpoint.s3[0].id : null
    ecr_api_endpoint_id = var.enable_vpc_endpoints ? aws_vpc_endpoint.ecr_api[0].id : null
    ecr_dkr_endpoint_id = var.enable_vpc_endpoints ? aws_vpc_endpoint.ecr_dkr[0].id : null
  }
}
