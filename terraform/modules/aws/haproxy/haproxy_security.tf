locals {
  haproxy_rc_cidrs       = ["0.0.0.0/0"]    # remote control of cluster
  haproxy_all_cidrs      = ["0.0.0.0/0"]    # end user access
  haproxy_internal_cidrs = ["10.50.0.0/16"] # internal network (2 AZs and subnets)
}

resource "aws_security_group" "haproxy_internal" {
  name   = "HA Proxy Internal SG"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = local.haproxy_internal_cidrs
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.haproxy_internal_cidrs
  }

  # VRRP protocol
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = 112
    cidr_blocks = local.haproxy_internal_cidrs
  }

  # Pings / ICMP
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = local.haproxy_internal_cidrs
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.haproxy_all_cidrs
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.haproxy_all_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = local.haproxy_internal_cidrs
  }
}

resource "aws_security_group" "haproxy_access" {
  name   = "HA Proxy Remote Access SG"
  vpc_id = var.vpc_id

  # Pings / ICMP
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = local.haproxy_internal_cidrs
  }

  # VRRP protocol
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = 112
    cidr_blocks = local.haproxy_internal_cidrs
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.haproxy_internal_cidrs
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.haproxy_all_cidrs
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.haproxy_all_cidrs
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = local.haproxy_rc_cidrs
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = local.haproxy_all_cidrs
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.haproxy_all_cidrs
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.haproxy_all_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = local.haproxy_internal_cidrs
  }
}

resource "aws_iam_instance_profile" "haproxy_instance_profile" {
  name = "iron_haproxy_instance_profile"
  role = aws_iam_role.haproxy_role.name
}

# define a document for tf syntax checking
data "aws_iam_policy_document" "haproxy_ec2_sts_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# define a role that can be used when creating ec2
resource "aws_iam_role" "haproxy_role" {
  name               = "iron_haproxy_role"
  assume_role_policy = data.aws_iam_policy_document.haproxy_ec2_sts_assume_role.json
}



# define a document for tf syntax checking
data "aws_iam_policy_document" "haproxy_ec2_document" {
  statement {
    sid = "eipChange"
    actions = [
      "ec2:AssignPrivateIpAddresses",
      "ec2:AssociateAddress",
      "ec2:DisassociateAddress",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:UnassignPrivateIpAddresses",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetObjectAcl",
      "s3:GetObjectTagging",
      "ssm:UpdateInstanceInformation"
    ]
    resources = concat(
      [for instance in aws_instance.ec2_haproxy : instance.arn],
      # [for nic in aws_network_interface.public : nic.arn],
      [aws_eip.haproxy_vip.arn],
      [aws_s3_bucket.haproxy_bucket.arn, "${aws_s3_bucket.haproxy_bucket.arn}/*"],
    )
  }
}

# this policy depends on arns from ec2 and eip resources
resource "aws_iam_policy" "haproxy_ec2_policy" {
  name   = "iron_haproxy_ec2_policy"
  policy = data.aws_iam_policy_document.haproxy_ec2_document.json
}

# finally attach the policy to the role
resource "aws_iam_role_policy_attachment" "haproxy_ec2_attachment" {
  role       = aws_iam_role.haproxy_role.name
  policy_arn = aws_iam_policy.haproxy_ec2_policy.arn
}
