locals {
  control_instance_type = "t3.medium"
  worker_instance_type  = "t3.large"
  iron_key              = aws_key_pair.iron_key.key_name
  az_worker_count       = 1 # Number of worker nodes per AZ

  aws_nodes = {
    "c1" = {
      instance_type   = local.control_instance_type
      key_name        = local.iron_key
      subnet_id       = aws_subnet.iron_control["az1"].id
      security_groups = [aws_security_group.iron_control.id]

      tags = {
        Name        = "c1"
        Description = "iron_k8s_control_1"
        Function    = "control"
        Zone        = "AZ 1"
      }
    }
    # "c2" = {
    #   instance_type   = local.control_instance_type
    #   key_name        = local.iron_key
    #   subnet_id       = aws_subnet.iron_control["az2"].id
    #   security_groups = [aws_security_group.iron_control.id]

    #   tags = {
    #     Name        = "c2"
    #     Description = "iron_k8s_control_2"
    #     Function    = "control"
    #     Zone        = "AZ 2"
    #   }
    # }
    # "c3" = {
    #   instance_type   = local.control_instance_type
    #   key_name        = local.iron_key
    #   subnet_id       = aws_subnet.iron_control["az3"].id
    #   security_groups = [aws_security_group.iron_control.id]

    #   tags = {
    #     Name        = "c3"
    #     Description = "iron_k8s_control_3"
    #     Function    = "control"
    #     Zone        = "AZ 3"
    #   }
    # }
    "w1" = {
      instance_type   = local.worker_instance_type
      key_name        = local.iron_key
      subnet_id       = aws_subnet.iron_worker["az1"].id
      security_groups = [aws_security_group.iron_worker.id]

      tags = {
        Name        = "w1"
        Description = "iron_k8s_worker_1"
        Function    = "worker"
        Zone        = "AZ 1"
      }
    }
    # "w2" = {
    #   instance_type   = local.worker_instance_type
    #   key_name        = local.iron_key
    #   subnet_id       = aws_subnet.iron_worker["az2"].id
    #   security_groups = [aws_security_group.iron_worker.id]

    #   tags = {
    #     Name        = "w2"
    #     Description = "iron_k8s_worker_2"
    #     Function    = "worker"
    #     Zone        = "AZ 2"
    #   }
    # }
    # "w3" = {
    #   instance_type   = local.worker_instance_type
    #   key_name        = local.iron_key
    #   subnet_id       = aws_subnet.iron_worker["az3"].id
    #   security_groups = [aws_security_group.iron_worker.id]

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
    #   subnet_id       = aws_subnet.iron_worker["az2"].id
    #   security_groups = [aws_security_group.iron_worker.id]

    #   tags = {
    #     Name        = "w4"
    #     Description = "iron_k8s_worker_4"
    #     Function    = "worker"
    #     Zone        = "AZ 2"
    #   }
    # }
  }
}


resource "aws_instance" "ec2_k8s_nodes" {
  for_each = local.aws_nodes

  ami                         = var.ami_id
  key_name                    = local.iron_key
  associate_public_ip_address = false

  subnet_id              = each.value.subnet_id
  instance_type          = each.value.instance_type
  vpc_security_group_ids = each.value.security_groups
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "16"
    delete_on_termination = true
  }
  tags = merge(each.value.tags, {
    Cluster = "iron_k8s_aws"
  })
}
