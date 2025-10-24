locals {
  aws_haproxy_nodes = {
    "ha1" = {
      subnet_id = aws_subnet.iron_public["az1"].id
      tags = {
        Name        = "haproxy1"
        Description = "iron_haproxy_primary"
        Zone        = "AZ 1"
      }
    }
    "ha2" = {
      subnet_id = aws_subnet.iron_public["az2"].id
      tags = {
        Name        = "haproxy2"
        Description = "iron_haproxy_primary"
        Zone        = "AZ 2"
      }
    }
  }
  haproxy_instance_type  = "t4g.micro"
  haproxy_ami            = "ami-06e880a88a1e3ebd9" # ubuntu 24.04 ARM 64bit
  haproxy_state_file_dir = "../../state_files"
}

resource "aws_instance" "ec2_haproxy" {
  for_each = local.aws_haproxy_nodes

  ami                         = local.haproxy_ami
  key_name                    = aws_key_pair.haproxy_key.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.haproxy_instance_profile.name
  instance_type               = local.haproxy_instance_type
  vpc_security_group_ids      = [aws_security_group.haproxy_access.id]
  subnet_id                   = each.value.subnet_id
  user_data_replace_on_change = true

  # most of the configuration will be done by ansible
  # pass the information required from TF to each VM in a script that can be sourced
  user_data = <<EOT
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y
    mkdir -p /etc/iron_haproxy
    chmod 755 /etc/iron_haproxy
    echo '# DO NOT EDIT - MAGANGED BY TF, ec2_haproyx.tf' > /etc/iron_haproxy/tf_values.sh
    echo "# Created on: $(date)" >> /etc/iron_haproxy/tf_values.sh
    echo "" >> /etc/iron_haproxy/tf_values.sh
    echo 'HAPROXY_VIP=${aws_eip.haproxy_vip.public_ip}' >> /etc/iron_haproxy/tf_values.sh
    echo 'HAPROXY_ALLOCATION_ID=${aws_eip.haproxy_vip.allocation_id}' >> /etc/iron_haproxy/tf_values.sh
    echo "" >> /etc/iron_haproxy/tf_values.sh
    EOT

  tags = merge(each.value.tags, {
    Cluster  = "iron_haproxy"
    Function = "haproxy"
  })
}

#create ssh keys
resource "tls_private_key" "haproxy_ssh_private_key" {
  algorithm = "ED25519"
}

# for now store backup copies of keys in state_files directory, for prod use AWS Secrets Manager
resource "local_file" "haproxy_ssh_private_key" {
  content         = tls_private_key.haproxy_ssh_private_key.private_key_openssh
  filename        = join("/", [local.haproxy_state_file_dir, "haproxy_id"])
  file_permission = "0600"
}

resource "local_file" "haproxy_ssh_pubkey" {
  content         = tls_private_key.haproxy_ssh_private_key.public_key_openssh
  filename        = join(".", [local_file.haproxy_ssh_private_key.filename, "pub"])
  file_permission = "0644"
}

resource "aws_key_pair" "haproxy_key" {
  key_name   = "iron-haproxy-key"
  public_key = tls_private_key.haproxy_ssh_private_key.public_key_openssh
}

resource "aws_eip" "haproxy_vip" {
  domain = "vpc"
}

output "primary_haproxy_ip" {
  value = aws_instance.ec2_haproxy["ha1"].public_ip
}

output "secondary_haproxy_ip" {
  value = aws_instance.ec2_haproxy["ha2"].public_ip
}

output "haproxy_vip" {
  value = aws_eip.haproxy_vip.public_ip
}

output "haproxy_vip_id" {
  value = aws_eip.haproxy_vip.allocation_id
}
