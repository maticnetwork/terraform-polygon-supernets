resource "aws_vpc" "devnet" {
  cidr_block           = var.devnet_vpc_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_vpc_dhcp_options" "devnet" {
  domain_name         = var.base_dn
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "devnet" {
  vpc_id          = aws_vpc.devnet.id
  dhcp_options_id = aws_vpc_dhcp_options.devnet.id
}

resource "aws_internet_gateway" "devnet" {
  vpc_id = aws_vpc.devnet.id
}

resource "aws_eip" "nat" {
  domain     = "vpc"
  count      = length(var.zones)
  depends_on = [aws_internet_gateway.devnet]
  tags = {
    Name = format("nat-%03d.%s", count.index + 1, var.base_dn)
  }
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.zones)
  subnet_id     = element(aws_subnet.devnet_public, count.index).id
  allocation_id = element(aws_eip.nat, count.index).id
  tags = {
    Name = format("nat-%03d.%s", count.index + 1, var.base_dn)
  }
}

resource "aws_subnet" "devnet_public" {
  vpc_id                  = aws_vpc.devnet.id
  count                   = length(var.zones)
  availability_zone       = element(var.zones, count.index)
  cidr_block              = element(var.devnet_public_subnet, count.index)
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.devnet]

  tags = {
    Name = format("k1dev-public-%03d.%s", count.index + 1, var.base_dn)
  }
}

resource "aws_subnet" "devnet_private" {
  vpc_id            = aws_vpc.devnet.id
  count             = length(var.zones)
  availability_zone = element(var.zones, count.index)
  cidr_block        = element(var.devnet_private_subnet, count.index)
  tags = {
    Name = format("k1dev-private-%03d.%s", count.index + 1, var.base_dn)
  }
}

resource "aws_route_table" "devnet_public" {
  vpc_id = aws_vpc.devnet.id
}
resource "aws_route_table" "devnet_private" {
  count  = length(var.zones)
  vpc_id = aws_vpc.devnet.id
  tags = {
    Name = format("k1dev-public-%03d.%s", count.index + 1, var.base_dn)
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.devnet_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.devnet.id
}
resource "aws_route" "private_nat_gateway" {
  count                  = length(var.zones)
  route_table_id         = element(aws_route_table.devnet_private, count.index).id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat, count.index).id
}
resource "aws_route_table_association" "public" {
  count          = length(var.zones)
  subnet_id      = element(aws_subnet.devnet_public, count.index).id
  route_table_id = aws_route_table.devnet_public.id
}
resource "aws_route_table_association" "private" {
  count          = length(var.zones)
  subnet_id      = element(aws_subnet.devnet_private, count.index).id
  route_table_id = element(aws_route_table.devnet_private, count.index).id
}

