# This is an ec2 vm to create an ansible control node
# It will have the ansible inventory and ssh keys to manage the k8s cluster
# It will also have the ansible playbooks to bootstrap the k8s cluster
locals {
  user_dir      = join("/", ["", "home", var.ami_user])
  ssh_dir       = join("/", [local.user_dir, ".ssh"])
  playbooks_dir = join("/", [local.user_dir, "ansible", "playbooks"])
  playbooks_src = join("/", ["..", "..", "ansible", "playbooks"])

  ansible_config_file = join("/", [local.user_dir, "ansible.cfg"])
  ansible_ec2_dns     = join(".", ["config", local.dns_iron])

  helm_src       = join("/", ["..", "..", "helm"])
  helm_dir       = join("/", [local.user_dir, "helm"])
  inventroy_path = join("/", [local.user_dir, "ansible", "inventory.ini"])
  ssh_key_path   = join("/", [local.state_file_dir, "iron_ansible_id"])

  conn_ssh_timeout   = "2m"
  conn_type          = "ssh"
  ansible_ssh_config = "~/.ssh/config"
}

resource "tls_private_key" "ansible_access_key" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "ansible_ssh_key" {
  key_name   = "ansible-ssh-key"
  public_key = tls_private_key.ansible_access_key.public_key_openssh
}

# for now store keys in state_files directory, for prod use AWS Secrets Manager
resource "local_file" "iron_ansible_ssh_private_key" {
  content         = tls_private_key.ansible_access_key.private_key_openssh
  filename        = local.ssh_key_path
  file_permission = "0600"
}

resource "local_file" "iron_ansible_ssh_pubkey" {
  content         = tls_private_key.ansible_access_key.public_key_openssh
  filename        = join(".", [local_file.iron_ansible_ssh_private_key.filename, "pub"])
  file_permission = "0644"
}

resource "aws_instance" "ec2_ansible" {
  ami                         = var.ami_id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.ansible_ssh_key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.iron_public["az1"].id
  vpc_security_group_ids      = [aws_security_group.iron_public.id]

  tags = {
    Name = "iron_ansible"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/ansible",
      "mkdir -p ~/.ssh",
      "chmod 700 ~/.ssh",
    ]

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = tls_private_key.ansible_access_key.private_key_openssh
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  # Upload the private key to the ansible control node
  provisioner "file" {
    content     = tls_private_key.iron_ssh_private_key.private_key_openssh
    destination = join("/", [local.ssh_dir, "iron_id"])

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = tls_private_key.ansible_access_key.private_key_openssh
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  provisioner "file" {
    content     = tls_private_key.iron_ssh_private_key.public_key_openssh
    destination = join("/", [local.ssh_dir, "iron_id.pub"])

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = tls_private_key.ansible_access_key.private_key_openssh
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  provisioner "file" {
    source      = local.inventory_file
    destination = local.inventroy_path

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = tls_private_key.ansible_access_key.private_key_openssh
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  provisioner "file" {
    content     = join("\n", [for key, values in local.aws_nodes : join(".", [values.tags.Name, local.dns_iron_private])])
    destination = join("/", [local.user_dir, "k8s_nodes.txt"])

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = tls_private_key.ansible_access_key.private_key_openssh
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  provisioner "file" {
    source      = local.playbooks_src #, join("/", [ "kube_install_nodes.yml"])
    destination = local.playbooks_dir # join("/", [, "kube_install_nodes.yml"])

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = tls_private_key.ansible_access_key.private_key_openssh
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  provisioner "file" {
    source      = local.helm_src
    destination = local.helm_dir

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = tls_private_key.ansible_access_key.private_key_openssh
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y ansible",
      "chmod 700 ~/.ssh",
      "chmod 600 ~/.ssh/iron_id",
      "chmod 644 ~/.ssh/iron_id.pub",
      "echo '[defaults]' > ${local.ansible_config_file}",
      "echo 'inventory=${join("/", [local.user_dir, "ansible", "inventory.ini"])}' >> ${local.ansible_config_file}",
      "echo 'host_key_checking=True' >> ${local.ansible_config_file}",
      "echo 'remote_user=${var.ami_user}' >> ${local.ansible_config_file}",
      "echo 'private_key_file=${local.ssh_key_path}' >> ${local.ansible_config_file}",
      "echo 'retry_files_enabled=False' >> ${local.ansible_config_file}",
      "echo 'Host c1' > ${local.ansible_ssh_config}",
      "chmod 600 ${local.ansible_ssh_config}",
      "echo '  Hostname c1.${local.dns_iron_private}' >> ${local.ansible_ssh_config}",
      "echo '  IdentitiesOnly yes' >> ${local.ansible_ssh_config}",
      "echo '  IdentityFile ~/.ssh/iron_id' >> ${local.ansible_ssh_config}",
      "echo '  StrictHostKeyChecking yes' >> ${local.ansible_ssh_config}",
      "echo '  User ${var.ami_user}' >> ${local.ansible_ssh_config}",
      "echo 'Host *.${local.dns_iron_private}' >> ${local.ansible_ssh_config}",
      "echo '  IdentitiesOnly yes' >> ${local.ansible_ssh_config}",
      "echo '  IdentityFile ~/.ssh/iron_id' >> ${local.ansible_ssh_config}",
      "echo '  StrictHostKeyChecking yes' >> ${local.ansible_ssh_config}",
      "echo '  User ${var.ami_user}' >> ${local.ansible_ssh_config}",
      "mkdir -p ~/.kube",
      "chmod 700 .kube",
      "sudo snap install kubectl --classic",
      "sudo snap install k9s --devmode",
      "sudo apt install net-tools",
      "sudo ln -s /snap/k9s/current/bin/k9s /usr/local/bin/k9s",
      "ssh-keyscan -H -p 22 -f ~/k8s_nodes.txt >> ~/.ssh/known_hosts",
    ]

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = tls_private_key.ansible_access_key.private_key_openssh
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  depends_on = [
    null_resource.config_files,
  ]
}

resource "aws_route53_record" "k8s_ansible" {
  zone_id = aws_route53_zone.iron.zone_id
  name    = local.ansible_ec2_dns
  type    = "A"
  ttl     = "300"
  records = [
    aws_instance.ec2_ansible.public_ip,
  ]
}

resource "null_resource" "ssh_known_hosts" {
  triggers = {
    always_run = timestamp() // Forces execution on every apply
  }

  provisioner "local-exec" {
    command     = <<EOT
rm -f ${local.ssh_known_hosts_file};
echo "# This file is managed by Terraform, ssh_hosts.tf. Do not edit!" > ${local.ssh_known_hosts_file};
ssh-keyscan -p 22 ${local.ansible_ec2_dns} >> ${local.ssh_known_hosts_file};
echo "# End of file" >> ${local.ssh_known_hosts_file};

EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [aws_instance.ec2_ansible]
}

# Output the public IP of the Ansible control node
output "ansible_control_node_ip" {
  value = aws_instance.ec2_ansible.public_ip
}

