resource "aws_lb" "kube_api" {
  name               = "kube-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets = [
    aws_subnet.iron_public["az1"].id,
    # aws_subnet.iron_public["az2"].id,
    # aws_subnet.iron_public["az3"].id,
  ]
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  security_groups = [
    aws_security_group.iron_public.id,
  ]
}

resource "aws_lb_target_group" "kube_api" {
  name     = "kube-nlb-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = aws_vpc.iron_vpc.id
}

resource "aws_lb_target_group_attachment" "kube_api" {
  # covert a list of instance objects to a map with instance ID as the key, and an instance
  # object as the value.
  for_each = {
    for k, v in aws_instance.ec2_k8s_nodes : k => v
    if v.tags["Function"] == "control"
  }

  target_group_arn = aws_lb_target_group.kube_api.arn
  target_id        = each.value.id
  port             = 6443
}

resource "aws_lb_listener" "kube_api" {
  load_balancer_arn = aws_lb.kube_api.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kube_api.arn
  }
}
