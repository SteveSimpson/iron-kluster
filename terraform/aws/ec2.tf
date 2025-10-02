locals {
  control_instance_type = "t3.medium"
  worker_instance_type  = "t3.large"
  iron_key              = aws_key_pair.iron_key.key_name
  az_worker_count       = 1 # Number of worker nodes per AZ
}

resource "aws_instance" "ec2_control_az1" {
  ami                         = var.ami_id
  subnet_id                   = aws_subnet.iron_control_subnet_1.id
  instance_type               = local.control_instance_type
  key_name                    = local.iron_key
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.iron_control.id]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "16"
    delete_on_termination = true
  }
  tags = {
    Name = "iron_k8s_control_az1"
  }
}

resource "aws_instance" "ec2_control_az2" {
  ami                         = var.ami_id
  subnet_id                   = aws_subnet.iron_control_subnet_2.id
  instance_type               = local.worker_instance_type
  key_name                    = local.iron_key
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.iron_control.id]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "16"
    delete_on_termination = true
  }
  tags = {
    Name = "iron_k8s_control_az2"
  }
}

resource "aws_instance" "ec2_worker_az1" {
  ami                         = var.ami_id
  count                       = local.az_worker_count
  subnet_id                   = aws_subnet.iron_worker_subnet_1.id
  instance_type               = local.worker_instance_type
  key_name                    = local.iron_key
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.iron_control.id]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "16"
    delete_on_termination = true
  }
  tags = {
    Name = "iron_k8s_worker_az1"
  }

}

resource "aws_instance" "ec2_worker_az2" {
  ami                         = var.ami_id
  count                       = local.az_worker_count
  subnet_id                   = aws_subnet.iron_worker_subnet_2.id
  instance_type               = local.worker_instance_type
  key_name                    = local.iron_key
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.iron_control.id]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "16"
    delete_on_termination = true
  }
  tags = {
    Name = "iron_k8s_worker_az2"
  }

}
