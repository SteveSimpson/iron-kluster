# This is an ec2 vm to create an ansible control node
# It will have the ansible inventory and ssh keys to manage the k8s cluster
# It will also have the ansible playbooks to bootstrap the k8s cluster
locals {
  user_dir      = join("/", ["", "home", var.ami_user])
  ssh_dir       = join("/", [local.user_dir, ".ssh"])
  playbooks_dir = join("/", [local.user_dir, "ansible", "playbooks"])

  ansible_config_file = join("/", [local.user_dir, "ansible.cfg"])

  helm_dir       = join("/", [local.user_dir, "helm"])
  inventroy_path = join("/", [local.user_dir, "ansible", "inventory.ini"])

  k8s_ssh_key_path   = join("/", [local.ssh_dir, "iron_id"])

  conn_ssh_timeout   = "2m"
  conn_type          = "ssh"
  ansible_ssh_config = "~/.ssh/config"

  haproxy_instances = join("\n", [for k, v in var.haproxy_instances : format("%s\t%s", v.id, v.private_ip)])
  haproxy_names = join("\n", [for k, v in var.haproxy_instances : format("haproxy-%s.iron-private.lcsas.net", (k + 1))])
}

resource "aws_instance" "ec2_ansible" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.bastion_ssh_key_name
  associate_public_ip_address = true
  subnet_id                   = var.bastion_subnet_id
  vpc_security_group_ids      = var.bastion_security_group_ids

  tags = {
    Name = "iron_ansible"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${var.hostname}",
      "mkdir -p ~/ansible",
      "mkdir -p ~/.ssh",
      "chmod 700 ~/.ssh",
    ]

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = var.bastion_ssh_private_key
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  # Upload the private key to the ansible control node
  provisioner "file" { # ssh key
    content     = var.k8s_ssh_key
    destination = local.k8s_ssh_key_path

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = var.bastion_ssh_private_key
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  provisioner "file" { # ssh pubkey
    content     = var.k8s_ssh_pubkey
    destination = join(".", [local.k8s_ssh_key_path, "pub"])

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = var.bastion_ssh_private_key
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  provisioner "file" { # k8s nodes list
    content     = local.k8s_nodes_list
    destination = join("/", [local.user_dir, local.k8s_nodes_list_filename])

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = var.bastion_ssh_private_key
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  provisioner "file" { # k8s nodes list
    content     = local.haproxy_names
    destination = join("/", [local.user_dir, "haproxy_nodes.txt"])

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = var.bastion_ssh_private_key
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  provisioner "file" { # ansible inventory
    content     = local.inventory_ini
    destination = local.inventroy_path

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = var.bastion_ssh_private_key
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  provisioner "file" { # ansible playbooks
    source      = var.playbook_dir    #, join("/", [ "kube_install_nodes.yml"])
    destination = local.playbooks_dir # join("/", [, "kube_install_nodes.yml"])

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = var.bastion_ssh_private_key
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }

  provisioner "file" { # helm charts
    source      = var.helm_dir
    destination = local.helm_dir

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = var.bastion_ssh_private_key
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
      "echo 'private_key_file=${local.k8s_ssh_key_path}' >> ${local.ansible_config_file}",
      "echo 'retry_files_enabled=False' >> ${local.ansible_config_file}",
      "echo 'Host c1' > ${local.ansible_ssh_config}",
      "chmod 600 ${local.ansible_ssh_config}",
      "echo '  Hostname c1.${var.k8s_private_dns}' >> ${local.ansible_ssh_config}",
      "echo '  IdentitiesOnly yes' >> ${local.ansible_ssh_config}",
      "echo '  IdentityFile ~/.ssh/iron_id' >> ${local.ansible_ssh_config}",
      "echo '  StrictHostKeyChecking yes' >> ${local.ansible_ssh_config}",
      "echo '  User ${var.ami_user}' >> ${local.ansible_ssh_config}",
      "echo 'Host *.${var.k8s_private_dns}' >> ${local.ansible_ssh_config}",
      "echo '  IdentitiesOnly yes' >> ${local.ansible_ssh_config}",
      "echo '  IdentityFile ~/.ssh/iron_id' >> ${local.ansible_ssh_config}",
      "echo '  StrictHostKeyChecking yes' >> ${local.ansible_ssh_config}",
      "echo '  User ${var.ami_user}' >> ${local.ansible_ssh_config}",
      "echo 'Host *' >> ${local.ansible_ssh_config}",
      "echo '  IdentitiesOnly yes' >> ${local.ansible_ssh_config}",
      "echo '  IdentityFile ~/.ssh/iron_id' >> ${local.ansible_ssh_config}",
      "echo '  StrictHostKeyChecking yes' >> ${local.ansible_ssh_config}",
      "echo '  User ${var.ami_user}' >> ${local.ansible_ssh_config}",
      "mkdir -p ~/.kube",
      "chmod 700 .kube",
      "sudo snap install kubectl --classic",
      "sudo snap install helm --classic",
      "sudo snap install k9s --devmode",
      "sudo apt install net-tools",
      "sudo ln -s /snap/k9s/current/bin/k9s /usr/local/bin/k9s",
      "echo \"# $(date)\" > ~/.ssh/known_hosts",
      "# ssh-keyscan -H -p 22 -f ~/k8s_nodes.txt >> ~/.ssh/known_hosts",
      "# ssh-keyscan -H -p 22 -f ~/haproxy_nodes.txt >> ~/.ssh/known_hosts",
    ]

    connection {
      type        = local.conn_type
      user        = var.ami_user
      private_key = var.bastion_ssh_private_key
      host        = self.public_ip
      timeout     = local.conn_ssh_timeout
    }
  }
}

resource "aws_route53_record" "k8s_ansible" {
  zone_id = var.public_dns_zone_id
  name    = var.hostname
  type    = "A"
  ttl     = "300"
  records = [
    aws_instance.ec2_ansible.public_ip,
  ]
}

# Output the public IP of the Ansible control node
output "ansible_control_node_ip" {
  value = aws_instance.ec2_ansible.public_ip
}

