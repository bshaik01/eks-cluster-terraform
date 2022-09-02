#######modules/vpc/main.tf


### VPC CONFIGURATION ###

resource "aws_vpc" "KP_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_availability_zones" "available" {
}

### INTERNET GATEWAY ###

resource "aws_internet_gateway" "KP_internet_gateway" {
  vpc_id = aws_vpc.KP_vpc.id

  lifecycle {
    create_before_destroy = true
  }
}


### PUB SUBNETS & ROUTE TABLES ###

resource "aws_subnet" "KP_public_subnets" {
  count                   = var.public_sn_count
  vpc_id                  = aws_vpc.KP_vpc.id
  cidr_block              = "10.123.${10 + count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]
}

resource "aws_route_table" "KP_public_rt" {
  vpc_id = aws_vpc.KP_vpc.id
}

resource "aws_route" "default_public_route" {
  route_table_id         = aws_route_table.KP_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.KP_internet_gateway.id
}

resource "aws_route_table_association" "KP_public_assoc" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.KP_public_subnets.*.id[count.index]
  route_table_id = aws_route_table.KP_public_rt.id
}


### PRIVATE SUBNETS & ROUTE TABLES ###

resource "aws_subnet" "KP_private_subnets" {
  count                   = var.private_sn_count
  vpc_id                  = aws_vpc.KP_vpc.id
  cidr_block              = "10.123.${20 + count.index}.0/24"
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index]

}

resource "aws_route_table" "KP_private_rt" {
  vpc_id = aws_vpc.KP_vpc.id
}

resource "aws_route" "default_private_route" {
  route_table_id         = aws_route_table.KP_private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.KP_ngw.id
}


resource "aws_route_table_association" "KP_private_assoc" {
  count          = var.private_sn_count
  route_table_id = aws_route_table.KP_private_rt.id
  subnet_id      = aws_subnet.KP_private_subnets.*.id[count.index]
}

### EIP AND NAT GATEWAY ###

resource "aws_eip" "KP_nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "KP_ngw" {
  allocation_id = aws_eip.KP_nat_eip.id
  subnet_id     = aws_subnet.KP_public_subnets[0].id
}