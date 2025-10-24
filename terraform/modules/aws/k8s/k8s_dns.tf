# Kubernetes Node DNS Records
resource "aws_route53_record" "k8s_node" {
  for_each = var.k8s_nodes
  zone_id  = var.dns_private_zone_id
  name     = each.key
  type     = "A"
  ttl      = "300"
  records  = [aws_instance.ec2_k8s_nodes[each.key].private_ip]
}
