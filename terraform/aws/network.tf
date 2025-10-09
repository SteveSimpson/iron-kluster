locals {
  subnet_prefix  = "10.50"
  subnet_postfix = "0/24"

  remote_cidrs   = ["0.0.0.0/0"]
  all_cidrs      = ["0.0.0.0/0"]
  internal_cidrs = ["10.50.0.0/16"]

  # if you add an AZ here, also add it to the nlb.tf, line 5 and ec2_nodes.tf, local.aws_nodes
  AZs = {
    "az1" = {name = var.az1, public = "11", control = "12", worker = "13"}
    # "az2" = {name = var.az2, public = "21", control = "22", worker = "23"}
    # "az3" = {name = var.az3, public = "31", control = "32", worker = "33"}
  }
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
  for_each      = { for k, v in local.AZs : k => v }
  vpc_id            = aws_vpc.iron_vpc.id
  availability_zone = each.value.name
  cidr_block        = join(".", [local.subnet_prefix, each.value.public, local.subnet_postfix])
  tags = {
    Name = "Iron Public Net ${each.key}"
  }
}

resource "aws_subnet" "iron_control" {
  for_each      = { for k, v in local.AZs : k => v }
  vpc_id            = aws_vpc.iron_vpc.id
  availability_zone = each.value.name
  cidr_block        = join(".", [local.subnet_prefix, each.value.control, local.subnet_postfix])
  tags = {
    Name = "Iron Control Net ${each.key}"
  }
}

resource "aws_subnet" "iron_worker" {
  for_each      = { for k, v in local.AZs : k => v }
  vpc_id            = aws_vpc.iron_vpc.id
  availability_zone = each.value.name
  cidr_block        = join(".", [local.subnet_prefix, each.value.worker, local.subnet_postfix])
  tags = {
    Name = "Iron Worker Net ${each.key}"
  }
}

resource "aws_eip" "iron_nat_ip" {
  for_each      = { for k, v in local.AZs : k => v }
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
  for_each = { for k, v in local.AZs : k => v }
  subnet_id      = aws_subnet.iron_public[each.key].id
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


resource "aws_security_group" "iron_public" {
  name   = "Public Access"
  vpc_id = aws_vpc.iron_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.remote_cidrs
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.remote_cidrs
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = local.remote_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = local.all_cidrs
  }
}

resource "aws_security_group" "iron_worker" {
  name   = "K8s Worker Ports"
  vpc_id = aws_vpc.iron_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.internal_cidrs
  }

  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = local.internal_cidrs
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = local.internal_cidrs
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = local.internal_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = local.all_cidrs
  }
}

resource "aws_security_group" "iron_control" {
  name   = "K8s Control Ports"
  vpc_id = aws_vpc.iron_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.internal_cidrs
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.internal_cidrs
  }

  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = local.internal_cidrs
  }

  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = local.internal_cidrs
  }

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = local.internal_cidrs
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = local.remote_cidrs
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = local.internal_cidrs
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = local.internal_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = local.all_cidrs
  }
}
