locals {
  # helper lists for control and worker hostnames
  control_hosts = [for k, v in var.k8s_nodes : "${k}.${var.k8s_private_dns}" if lookup(v.tags, "Function", "") == "control"]
  worker_hosts  = [for k, v in var.k8s_nodes  : "${k}.${var.k8s_private_dns}" if lookup(v.tags, "Function", "") == "worker"]
  haproxy_hosts = [for k, v in var.haproxy_instances : "haproxy-${k+1}.${var.k8s_private_dns}"]

  k8s_nodes_list = join("\n", [for key, values in var.k8s_nodes : join(".", [values.tags.Name, var.k8s_private_dns])])
  k8s_nodes_list_filename = "k8s_nodes.txt"

  inventory_ini = templatefile("${path.module}/templates/inventory.tmpl", {
    control_hosts = join("\n", local.control_hosts)
    worker_hosts  = join("\n", local.worker_hosts)
    haproxy_hosts = join("\n", local.haproxy_hosts)
    ansible_user  = var.ami_user
    ansible_key   = local.k8s_ssh_key_path
    haproxy_stats_password = random_password.haproxy_stats_password.result
  })
}

resource "local_file" "inventory_ini" {
  content  = local.inventory_ini
  filename = abspath("${var.local_state_path}/inventory.ini")
}

resource "local_file" "k8s_nodes_list" {
  content  = local.k8s_nodes_list
  filename = abspath("${var.local_state_path}/${local.k8s_nodes_list_filename}")
}

resource "random_password" "haproxy_stats_password" {
  length           = 32
  special          = false
}
