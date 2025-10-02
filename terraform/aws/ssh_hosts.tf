locals {
  worker_nodes = concat(
    [for i, v in aws_route53_record.k8s_worker1 : { host = v.name, port = 22 }],
    [for i, v in aws_route53_record.k8s_worker2 : { host = v.name, port = 22 }],
  )

  control_nodes = concat(
    [{ host = aws_route53_record.k8s_control1.name, port = 22 }],
    [{ host = aws_route53_record.k8s_control2.name, port = 22 }],
  )

  ssh_hosts = concat(
    local.worker_nodes,
    local.control_nodes,
  )

  # File names must also be updated null_resource.config_files below
  # relative paths must be synced from from TF to Ansible
  state_file_dir       = "../../state_files"
  inventory_file       = join("/", [local.state_file_dir, "inventory.ini"])
  ssh_known_hosts_file = join("/", [local.state_file_dir, "ssh_known_hosts"])
}

#create ssh keys
resource "tls_private_key" "iron_ssh_private_key" {
  algorithm = "ED25519"
}

resource "local_file" "iron_ssh_private_key" {
  content = tls_private_key.iron_ssh_private_key.private_key_openssh
  filename = join("/", [local.state_file_dir, "iron_id"])
  file_permission = "0600"
}

resource "local_file" "iron_ssh_pubkey" {
  content = tls_private_key.iron_ssh_private_key.public_key_openssh
  filename = join(".", [local_file.iron_ssh_private_key.filename, "pub"])
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
%{for i, host in local.ssh_hosts}
    ssh-keyscan -p ${host.port} ${host.host} >> ${local.ssh_known_hosts_file};
%{endfor~}
echo "# This file is managed by Terraform, ssh_hosts.tf. Do not edit!" > ${local.inventory_file};
echo "[kube-control-plane]" > ${local.inventory_file};
%{for i, host in local.control_nodes}
    echo ${host.host} >> ${local.inventory_file};
%{endfor~}
echo "" >> ${local.inventory_file};

echo "[kube-worker-nodes]" >> ${local.inventory_file};
%{for i, host in local.worker_nodes}
    echo ${host.host} >> ${local.inventory_file};
%{endfor~}
echo "" >> ${local.inventory_file};

echo "[all:vars]" >> ${local.inventory_file};
echo "ansible_user=ubuntu" >> ${local.inventory_file};
echo "ansible_ssh_private_key_file=../state_files/iron_id" >> ${local.inventory_file};
echo "ansible_ssh_common_args='-o UserKnownHostsFile=../state_files/ssh_known_hosts -o StrictHostKeyChecking=yes'" >> ${local.inventory_file};
EOT
        interpreter = ["/bin/bash", "-c"]
    }
}

