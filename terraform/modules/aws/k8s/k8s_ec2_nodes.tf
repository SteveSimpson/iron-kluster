resource "aws_instance" "ec2_k8s_nodes" {
  for_each = var.k8s_nodes

  ami                         = var.ami_id
  key_name                    = var.ssh_key_name
  associate_public_ip_address = false

  subnet_id              = each.value.subnet_id
  instance_type          = each.value.instance_type
  vpc_security_group_ids = each.value.security_groups

  user_data = <<-EOT
    #!/bin/bash
    #
    hostnamectl set-hostname "${each.key}"
  EOT

  root_block_device {
    volume_type           = "gp2"
    volume_size           = "16"
    delete_on_termination = true
  }
  tags = merge(each.value.tags, {
    Cluster = "iron_k8s_aws"
  })
}
