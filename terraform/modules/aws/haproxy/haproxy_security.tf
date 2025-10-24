locals {
  haproxy_rc_cidrs       = ["0.0.0.0/0"]    # remote control of cluster
  haproxy_all_cidrs      = ["0.0.0.0/0"]    # end user access
  haproxy_internal_cidrs = ["10.50.0.0/16"] # internal network (2 AZs and subnets)
}

resource "aws_security_group" "haproxy_access" {
  name   = "HA Proxy Remote Access SG"
  vpc_id = aws_vpc.iron_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.haproxy_rc_cidrs
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.haproxy_all_cidrs
  }

  ingress {
    from_port   = 433
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.haproxy_all_cidrs
  }

  ingress {
    from_port   = 6433
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = local.haproxy_rc_cidrs
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
      "ec2:AssociateAddress",
      "ec2:DisassociateAddress",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
    ]
    resources = [
      aws_instance.ec2_haproxy["ha1"].arn,
      aws_instance.ec2_haproxy["ha2"].arn,
      aws_eip.haproxy_vip.arn,
    ]
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
