# modules/vpc/nat.tf
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? var.availability_zones_count : 0
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = merge(var.additional_tags, {
    Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? var.availability_zones_count : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.additional_tags, {
    Name = "${local.name_prefix}-nat-gw-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Routes to NAT Gateways
resource "aws_route" "private_nat_gateway" {
  count                  = var.enable_nat_gateway ? var.availability_zones_count : 0
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[count.index].id

  timeouts {
    create = "5m"
  }
}