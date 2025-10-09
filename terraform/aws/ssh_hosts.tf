# This file syncs Terraform with Ansible by generating the following files:
# - state_files/inventory.ini
# - state_files/ssh_known_hosts

locals {
  # File names must also be updated null_resource.config_files below
  # relative paths must be synced from from TF to Ansible
  state_file_dir       = "../../state_files"
  inventory_file       = join("/", [local.state_file_dir, "inventory.ini"])
  ssh_known_hosts_file = join("/", [local.state_file_dir, "ssh_known_hosts"])
  ssh_port             = 22
}

#create ssh keys
resource "tls_private_key" "iron_ssh_private_key" {
  algorithm = "ED25519"
}

# for now store backup copies of keys in state_files directory, for prod use AWS Secrets Manager
resource "local_file" "iron_ssh_private_key" {
  content         = tls_private_key.iron_ssh_private_key.private_key_openssh
  filename        = join("/", [local.state_file_dir, "iron_id"])
  file_permission = "0600"
}

resource "local_file" "iron_ssh_pubkey" {
  content         = tls_private_key.iron_ssh_private_key.public_key_openssh
  filename        = join(".", [local_file.iron_ssh_private_key.filename, "pub"])
  file_permission = "0644"
}

resource "aws_key_pair" "iron_key" {
  key_name   = "iron-ssh-key"
  public_key = tls_private_key.iron_ssh_private_key.public_key_openssh
}

resource "null_resource" "config_files" {
  triggers = {
    always_run = timestamp() // Forces execution on every apply
  }

  provisioner "local-exec" {
    command     = <<EOT
rm -f ${local.ssh_known_hosts_file};
echo "# This file is managed by Terraform, ssh_hosts.tf. Do not edit!" > ${local.ssh_known_hosts_file};
echo "# This file is managed by Terraform, ssh_hosts.tf. Do not edit!" > ${local.inventory_file};
echo "[kube_control_plane]" >> ${local.inventory_file};
echo "[kube_worker_nodes]" >> ${local.inventory_file}.workers;
%{for key, values in local.aws_nodes}
  if  [[ "${values.tags.Description}" == *"_control"* ]]; then
    echo ${values.tags.Name}.${local.dns_iron_private} >> ${local.inventory_file};
  else
    echo ${values.tags.Name}.${local.dns_iron_private} >> ${local.inventory_file}.workers;
  fi
%{endfor~}

echo "" >> ${local.inventory_file};
cat ${local.inventory_file}.workers >> ${local.inventory_file};
rm -f ${local.inventory_file}.workers;
echo "" >> ${local.inventory_file};
echo "[all:vars]" >> ${local.inventory_file};
echo "ansible_user=${var.ami_user}" >> ${local.inventory_file};
echo "ansible_ssh_private_key_file=~/.ssh/iron_id" >> ${local.inventory_file};

EOT
    interpreter = ["/bin/bash", "-c"]
  }

  depends_on = [aws_instance.ec2_k8s_nodes]
}

