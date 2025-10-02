locals {
  subnet_prefix  = "10.50"
  subnet_postfix = "0/24"

  remote_cidrs = ["0.0.0.0/0"]

  iron_subnets = {
    "public_control_az1" = aws_subnet.iron_control_subnet_1.id,
    "public_worker_az1"  = aws_subnet.iron_worker_subnet_1.id,
    "public_control_az2" = aws_subnet.iron_control_subnet_2.id,
    "public_worker_az2"  = aws_subnet.iron_worker_subnet_2.id,
  }
}

resource "aws_vpc" "iron_vpc" {
  cidr_block = join(".", [local.subnet_prefix, "0.0/16"])

  tags = {
    Name = "Iron VPC"
  }
}

resource "aws_subnet" "iron_control_subnet_1" {
  vpc_id            = aws_vpc.iron_vpc.id
  cidr_block        = join(".", [local.subnet_prefix, "1", local.subnet_postfix])
  availability_zone = var.az1

  tags = {
    Name = "Iron K8s Control Subnet for 1st AZ"
  }
}

resource "aws_subnet" "iron_worker_subnet_1" {
  vpc_id            = aws_vpc.iron_vpc.id
  cidr_block        = join(".", [local.subnet_prefix, "3", local.subnet_postfix])
  availability_zone = var.az1

  tags = {
    Name = "Iron K8s Worker Subnet for 1st AZ"
  }
}

resource "aws_subnet" "iron_control_subnet_2" {
  vpc_id            = aws_vpc.iron_vpc.id
  cidr_block        = join(".", [local.subnet_prefix, "2", local.subnet_postfix])
  availability_zone = var.az2

  tags = {
    Name = "Iron K8s Control Subnet for 2nd AZ"
  }
}

resource "aws_subnet" "iron_worker_subnet_2" {
  vpc_id            = aws_vpc.iron_vpc.id
  cidr_block        = join(".", [local.subnet_prefix, "4", local.subnet_postfix])
  availability_zone = var.az2

  tags = {
    Name = "Iron K8s Worker Subnet for 2nd AZ"
  }
}


resource "aws_internet_gateway" "iron_gw" {
  vpc_id = aws_vpc.iron_vpc.id

  tags = {
    Name = "Iron Internet Gateway"
  }
}

# todo - lock this down
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
    Name = "Public Route Table"
  }
}

# todo - split this out and lock it down
resource "aws_route_table_association" "public_routes_assoc" {
  # for_each = toset(local.iron_subnets)
  for_each       = { for k, v in local.iron_subnets : k => v if startswith(k, "public") }
  subnet_id      = each.value
  route_table_id = aws_route_table.public_routes.id
}

resource "aws_security_group" "iron_control" {
  name   = "K8 Control Ports"
  vpc_id = aws_vpc.iron_vpc.id

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

  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = local.remote_cidrs
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.remote_cidrs
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = local.remote_cidrs
  }
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = local.remote_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = local.remote_cidrs
  }
}
