locals {

}

resource "aws_lb" "kube_api" {
  name                             = "kube-nlb"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = var.k8s_public_subnet_list
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  security_groups                  = var.k8s_security_groups
}

resource "aws_lb_target_group" "kube_api" {
  name     = "kube-nlb-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group_attachment" "kube_api" {
  # covert a list of instance objects to a map with instance ID as the key, and an instance
  # object as the value.
  
  # for_each  {
  #   for k, v in var.k8s_nodes : k => v
  #   if v.tags["Function"] == "control"
  # }
  # for_each = toset(var.control_node_ids)
  count          = var.control_node_count

  target_group_arn = aws_lb_target_group.kube_api.arn
  target_id        = var.control_node_ids[count.index]
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

# Kubernetes API Load Balancer DNS Record (for now just points to control nodes)
resource "aws_route53_record" "k8s_api" {
  zone_id = var.dns_zone_id
  name    = var.dns_hostname
  type    = "CNAME"
  ttl     = "300"
  records = [
    aws_lb.kube_api.dns_name,
  ]
}
