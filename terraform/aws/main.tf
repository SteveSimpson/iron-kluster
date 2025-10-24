locals {
  control_instance_type = "t3.medium"
  worker_instance_type  = "t3.large"
  iron_k8s_key_name     = "iron_k8s_key"
  ansible_key_name      = "iron_ansible_key"
  state_file_dir        = abspath("${path.root}/../../state_files")

  aws_nodes = {
    "c1" = {
      instance_type   = local.control_instance_type
      key_name        = module.iron_k8s_key.aws_key_pair_name
      subnet_id       = aws_subnet.iron_control["az1"].id
      security_groups = [aws_security_group.iron_control.id, aws_security_group.calico.id]

      tags = {
        Name        = "c1"
        Description = "iron_k8s_control_1"
        Function    = "control"
        Zone        = "AZ 1"
      }
    }
    "c2" = {
      instance_type   = local.control_instance_type
      key_name        = module.iron_k8s_key.aws_key_pair_name
      subnet_id       = aws_subnet.iron_control["az2"].id
      security_groups = [aws_security_group.iron_control.id, aws_security_group.calico.id]

      tags = {
        Name        = "c2"
        Description = "iron_k8s_control_2"
        Function    = "control"
        Zone        = "AZ 2"
      }
    }
    # "c3" = {
    #   instance_type   = local.control_instance_type
    #   key_name        = local.iron_key
    #   subnet_id       = aws_subnet.iron_control["az3"].id
    #   security_groups = [aws_security_group.iron_control.id, aws_security_group.calico.id]

    #   tags = {
    #     Name        = "c3"
    #     Description = "iron_k8s_control_3"
    #     Function    = "control"
    #     Zone        = "AZ 3"
    #   }
    # }
    "w1" = {
      instance_type   = local.worker_instance_type
      key_name        = module.iron_k8s_key.aws_key_pair_name
      subnet_id       = aws_subnet.iron_worker["az1"].id
      security_groups = [aws_security_group.iron_worker.id, aws_security_group.calico.id]

      tags = {
        Name        = "w1"
        Description = "iron_k8s_worker_1"
        Function    = "worker"
        Zone        = "AZ 1"
      }
    }
    "w2" = {
      instance_type   = local.worker_instance_type
      key_name        = module.iron_k8s_key.aws_key_pair_name
      subnet_id       = aws_subnet.iron_worker["az2"].id
      security_groups = [aws_security_group.iron_worker.id, aws_security_group.calico.id]

      tags = {
        Name        = "w2"
        Description = "iron_k8s_worker_2"
        Function    = "worker"
        Zone        = "AZ 2"
      }
    }
    # "w3" = {
    #   instance_type   = local.worker_instance_type
    #   key_name        = local.iron_key
    #   subnet_id       = aws_subnet.iron_worker["az3"].id
    #   security_groups = [aws_security_group.iron_worker.id, aws_security_group.calico.id]

    #   tags = {
    #     Name        = "w3"
    #     Description = "iron_k8s_worker_3"
    #     Function    = "worker"
    #     Zone        = "AZ 3"
    #   }
    # }
    # "w4" = {
    #   instance_type   = local.worker_instance_type
    #   key_name        = local.iron_key
    #   subnet_id       = aws_subnet.iron_worker["az1"].id
    #   security_groups = [aws_security_group.iron_worker.id, aws_security_group.calico.id]

    #   tags = {
    #     Name        = "w4"
    #     Description = "iron_k8s_worker_4"
    #     Function    = "worker"
    #     Zone        = "AZ 1"
    #   }
    # }
  }

  tags = {
    Cluster = "iron_k8a"
  }
}

# the internal k8s cluster ssh key
module "iron_k8s_key" {
  source = "../modules/local/sshkey"

  key_name = local.iron_k8s_key_name

  local_state_path = local.state_file_dir

  tags = merge(local.tags, {
    KeyName = local.iron_k8s_key_name
  })
}

# the external key to access the bastion / ansible host
module "iron_ansible_key" {
  source = "../modules/local/sshkey"

  key_name         = local.ansible_key_name
  local_state_path = local.state_file_dir

  tags = merge(local.tags, {
    KeyName = local.ansible_key_name
  })
}

module "iron_aws_k8s" {
  source = "../modules/aws/k8s"

  k8s_nodes           = local.aws_nodes
  ami_id              = var.ami_id
  dns_private_zone_id = aws_route53_zone.private_iron.zone_id
  dns_tld             = var.dns_tld
  ssh_key_name        = module.iron_k8s_key.aws_key_pair_name
  tags                = local.tags

}

module "iron_bastion" {
  source = "../modules/aws/bastion"

  ami_id                     = var.ami_id
  ami_user                   = var.ami_user
  az                         = var.az1
  bastion_ssh_key_name       = module.iron_ansible_key.aws_key_pair_name
  bastion_security_group_ids = [aws_security_group.iron_public.id]
  local_state_path           = local.state_file_dir
  tags                       = local.tags
  bastion_subnet_id          = aws_subnet.iron_public["az1"].id
  k8s_nodes                  = local.aws_nodes
  k8s_private_dns            = local.dns_iron_private
  k8s_ssh_key                = module.iron_k8s_key.ssh_private_key
  k8s_ssh_pubkey             = module.iron_k8s_key.ssh_public_key
  playbook_dir               = abspath("${path.root}/../../ansible/playbooks")
  helm_dir                   = abspath("${path.root}/../../helm")
  public_dns_zone_id         = aws_route53_zone.iron.id
  bastion_ssh_private_key    = module.iron_ansible_key.ssh_private_key

  depends_on = [
    module.iron_k8s_key,
    module.iron_ansible_key,
    module.iron_aws_k8s,
  ]
}

module "iron_nlb" {
  source = "../modules/aws/nlb"

  dns_hostname           = "api"
  dns_zone_id            = aws_route53_zone.iron.zone_id
  # k8s_nodes              = module.iron_aws_k8s.k8s_nodes
  control_node_ids = module.iron_aws_k8s.k8s_contol_nodes
  vpc_id                 = aws_vpc.iron_vpc.id
  k8s_public_subnet_list = [for subnet in aws_subnet.iron_public : subnet.id]
  k8s_security_groups    = [aws_security_group.iron_public.id]
}

# module "haproxy" {
#   source = "../modules/aws/haproxy"
# }


