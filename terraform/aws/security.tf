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

  ingress {
    from_port   = 10250
    to_port     = 10250
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

resource "aws_security_group" "calico" {
  name   = "K8s ports for Calico CNI"
  vpc_id = aws_vpc.iron_vpc.id

  # ip in ip
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = 4
    cidr_blocks = local.internal_cidrs
  }

  # BGP
  ingress {
    from_port   = 179
    to_port     = 179
    protocol    = "tcp"
    cidr_blocks = local.internal_cidrs
  }

  # vxlan
  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = local.internal_cidrs
  }

  # typhia
  ingress {
    from_port   = 5473
    to_port     = 5473
    protocol    = "tcp"
    cidr_blocks = local.internal_cidrs
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

  # etcd
  ingress {
    from_port   = 2379
    to_port     = 2379
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
