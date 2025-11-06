locals {
  subnet_prefix  = "10.50"
  subnet_postfix = "0/24"

  remote_cidrs   = ["0.0.0.0/0"]
  all_cidrs      = ["0.0.0.0/0"]
  internal_cidrs = ["10.50.0.0/16"]

  # if you add an AZ here, also add it to the nlb.tf, line 5 and ec2_nodes.tf, local.aws_nodes
  AZs = {
    "az1" = { name = var.az1, public = "11", control = "12", worker = "13", haproxy = "14" }
    "az2" = { name = var.az2, public = "21", control = "22", worker = "23", haproxy = "24" }
    # "az3" = {name = var.az3, public = "31", control = "32", worker = "33"}
  }

  HAProxy_AZs = {
    "az1" = { 
      name = var.az1, 
      public = "10.50.10.0/28", 
      private = "10.50.10.16/28",
    }
    "az2" = { 
      name = var.az2, 
      public = "10.50.10.32/28", 
      private = "10.50.10.48/28",
    }
  }

  haproxy_private_subnet_ids = [for k, v in local.HAProxy_AZs : aws_subnet.iron_haproxy_private[k].id]
  haproxy_public_subnet_ids = [for k, v in local.HAProxy_AZs : aws_subnet.iron_haproxxy_public[k].id]
}

resource "aws_vpc" "iron_vpc" {
  cidr_block = join(".", [local.subnet_prefix, "0.0/16"])

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Iron VPC"
  }
}

resource "aws_internet_gateway" "iron_gw" {
  vpc_id = aws_vpc.iron_vpc.id

  tags = {
    Name = "Iron Internet Gateway"
  }
}

resource "aws_subnet" "iron_public" {
  for_each          = { for k, v in local.AZs : k => v }
  vpc_id            = aws_vpc.iron_vpc.id
  availability_zone = each.value.name
  cidr_block        = join(".", [local.subnet_prefix, each.value.public, local.subnet_postfix])
  tags = {
    Name = "Iron Public Net ${each.key}"
  }
}

resource "aws_subnet" "iron_control" {
  for_each          = { for k, v in local.AZs : k => v }
  vpc_id            = aws_vpc.iron_vpc.id
  availability_zone = each.value.name
  cidr_block        = join(".", [local.subnet_prefix, each.value.control, local.subnet_postfix])
  tags = {
    Name = "Iron Control Net ${each.key}"
  }
}

resource "aws_subnet" "iron_worker" {
  for_each          =  { for k, v in local.AZs : k => v }
  vpc_id            = aws_vpc.iron_vpc.id
  availability_zone = each.value.name
  cidr_block        = join(".", [local.subnet_prefix, each.value.worker, local.subnet_postfix])
  tags = {
    Name = "Iron Worker Net ${each.key}"
  }
}

resource "aws_subnet" "iron_haproxy_private" {
  for_each          = { for k, v in local.HAProxy_AZs : k => v  }
  vpc_id            = aws_vpc.iron_vpc.id
  availability_zone = each.value.name
  cidr_block        = each.value.private
  tags = {
    Name = "Iron HAProxy Net ${each.key}"
  }
}

resource "aws_subnet" "iron_haproxxy_public" {
  for_each          = { for k, v in local.HAProxy_AZs : k => v }
  vpc_id            = aws_vpc.iron_vpc.id
  availability_zone = each.value.name
  cidr_block        = each.value.public
  tags = {
    Name = "Iron HAProxy Public Net ${each.key}"
  }
}

resource "aws_eip" "iron_nat_ip" {
  for_each = { for k, v in local.AZs : k => v }
  domain   = "vpc"

  tags = {
    Name   = "Iron NAT IP ${each.key}"
    Subnet = each.key
  }
}

resource "aws_nat_gateway" "iron_nat_gw" {
  for_each      = { for k, v in local.AZs : k => v }
  subnet_id     = aws_subnet.iron_public[each.key].id
  allocation_id = aws_eip.iron_nat_ip[each.key].id

  tags = {
    Name   = "Iron NAT ${each.key}"
    Subnet = each.key
  }

  depends_on = [aws_internet_gateway.iron_gw]
}

resource "aws_route_table" "public_routes" {
  vpc_id = aws_vpc.iron_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.iron_gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.iron_gw.id
  }

  tags = {
    Name = "Iron Public Route Table"
  }
}

resource "aws_route_table" "private_routes" {
  for_each = { for k, v in local.AZs : k => v }
  vpc_id   = aws_vpc.iron_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.iron_nat_gw[each.key].id
  }

  tags = {
    Name   = "Iron Private RT ${each.key}"
    Subnet = each.key
  }
}

resource "aws_route_table_association" "public_routes_assoc" {
  for_each       = { for k, v in local.AZs : k => v }
  subnet_id      = aws_subnet.iron_public[each.key].id
  route_table_id = aws_route_table.public_routes.id
}

resource "aws_route_table_association" "public_routes_assoc_haproxy" {
  for_each       = { for k, v in local.HAProxy_AZs : k => v }
  subnet_id      = aws_subnet.iron_haproxxy_public[each.key].id
  route_table_id = aws_route_table.public_routes.id
}

resource "aws_route_table_association" "private_routes_assoc_control" {
  for_each = { for k, v in local.AZs : k => v }

  subnet_id      = aws_subnet.iron_control[each.key].id
  route_table_id = aws_route_table.private_routes[each.key].id
}

resource "aws_route_table_association" "private_routes_assoc_worker" {
  for_each = { for k, v in local.AZs : k => v }

  subnet_id      = aws_subnet.iron_worker[each.key].id
  route_table_id = aws_route_table.private_routes[each.key].id
}

resource "aws_route_table_association" "private_routes_assoc_haproxy" {
  for_each = { for k, v in local.HAProxy_AZs : k => v }

  subnet_id      = aws_subnet.iron_haproxy_private[each.key].id
  route_table_id = aws_route_table.private_routes[each.key].id
}
