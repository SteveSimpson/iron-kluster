data "aws_region" "current" {}

resource "aws_instance" "ec2_haproxy" {
  count = length(var.public_subnet_ids)

  ami                         = var.ami_id
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.haproxy_instance_profile.name
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.haproxy_access.id]
  subnet_id                   = var.private_subnet_ids[count.index]
  user_data_replace_on_change = true

  # Interesting mix of TF & Ansible
  # TF has all the information to create the configs, but implemnting the configs needs to be done after setup
  # Ansible will be used to setup the services. It provides better debugging and idempotency.
  # The user_data script will do the minimum to setup the host and pass facts to ansible
  user_data = <<-EOT
    #!/bin/bash
    #
    hostnamectl set-hostname "haproxy-${count.index + 1}"

    apt update
    apt install -y s3fs
  
    mkdir -p /mnt/iron_haproxy
    mkdir -p /etc/iron_haproxy/facts
    chmod 755 /mnt/iron_haproxy /etc/iron_haproxy /etc/iron_haproxy/facts

    # mount s3 bucket using iam role so that it is available for ansible to use
    echo "${local.haproxy_s3_bucket_name} /mnt/iron_haproxy fuse.s3fs _netdev,allow_other,iam_role=iron_haproxy_role 0 0" >> /etc/fstab

    echo "Files in this directory are managed by terraform, haproyx_ec2.tf." > /etc/iron_haproxy/facts/README.txt
    echo "Do not edit them directly." >> /etc/iron_haproxy/facts/README.txt
    echo "" >> /etc/iron_haproxy/facts/README.txt
    echo "They are to be slurped from Ansible to be used as facts during playbook runs." >> /etc/iron_haproxy/facts/README.txt
    echo "" >> /etc/iron_haproxy/facts/README.txt

    echo "${count.index}" > /etc/iron_haproxy/facts/haproxy_index
    echo "${aws_eip.haproxy_vip.public_ip}" > /etc/iron_haproxy/facts/haproxy_vip4

    echo "${data.aws_region.current.region}" > /etc/iron_haproxy/facts/aws_region
    chnod 644 /etc/iron_haproxy/facts/*

    echo '# DO NOT EDIT - MAGANGED BY TF, haproyx_ec2.tf' > /etc/iron_haproxy/tf_values.sh
    echo "# Created on: $(date)" >> /etc/iron_haproxy/tf_values.sh
    echo "" >> /etc/iron_haproxy/tf_values.sh
    echo 'HAPROXY_VIP=${aws_eip.haproxy_vip.public_ip}' >> /etc/iron_haproxy/tf_values.sh
    echo 'HAPROXY_ALLOCATION_ID=${aws_eip.haproxy_vip.allocation_id}' >> /etc/iron_haproxy/tf_values.sh

    echo 'HAPROXY_INSTANCE_INDEX=${count.index}' >> /etc/iron_haproxy/tf_values.sh
    echo 'AWS_REGION=${data.aws_region.current.region}' >> /etc/iron_haproxy/tf_values.sh
    echo "" >> /etc/iron_haproxy/tf_values.sh
    chmod 600 /etc/iron_haproxy/tf_values.sh

    # Run updates here to ensure latest security patches are applied
    apt -y upgrade
    mount -a

    reboot
  EOT

  tags = {
    Cluster  = "iron_haproxy"
    Function = "haproxy"
    Name     = "iron_haproxy-${count.index + 1}"
  }
}

# resource "aws_network_interface" "public" {
#   count = length(var.public_subnet_ids)

#   subnet_id       = var.public_subnet_ids[count.index]
#   security_groups = [aws_security_group.haproxy_access.id]

#   tags = {
#     Name = "iron_haproxy_public_${count.index + 1}"
#   }
  
# }

# resource "aws_network_interface_attachment" "public_attachment" {
#   count = length(var.public_subnet_ids)
#   instance_id          = aws_instance.ec2_haproxy[count.index].id
#   network_interface_id = aws_network_interface.public[count.index].id
#   device_index         = 1
# }

resource "aws_eip" "haproxy_vip" {
  domain = "vpc"

  tags = {
    Name = "iron_haproxy_vip"
  }
}

# 42 echo "${aws_network_interface.public[count.index].id}" > /etc/iron_haproxy/facts/haproxy_interface_id
# 42  
# 55  echo 'HAPROXY_INTERFACE_ID=${aws_network_interface.public[count.index].id}' >> /etc/iron_haproxy/tf_values.sh
