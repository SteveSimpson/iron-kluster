locals {
  private_zone = join("-", [var.dns_public_sub, "private"])

  dns_iron         = join(".", [var.dns_public_sub, var.dns_tld])
  dns_iron_private = join(".", [local.private_zone, var.dns_tld])
}

data "aws_route53_zone" "tld" {
  name         = var.dns_tld
  private_zone = false
}

resource "aws_route53_zone" "iron" {
  name          = local.dns_iron
  force_destroy = true

  tags = {
    Name = "Iron Kluster Public DNS Zone"
  }
}

resource "aws_route53_zone" "private_iron" {
  name          = local.dns_iron_private
  force_destroy = true

  vpc {
    vpc_id = aws_vpc.iron_vpc.id
  }

  tags = {
    Name = "Iron Kluster Private DNS Zone"
  }
}

resource "aws_route53_record" "iron_ns" {
  zone_id = data.aws_route53_zone.tld.zone_id
  name    = local.dns_iron
  type    = "NS"
  ttl     = "300"
  records = aws_route53_zone.iron.name_servers
}

resource "aws_route53_record" "private_iron_ns" {
  zone_id = data.aws_route53_zone.tld.zone_id
  name    = local.private_zone
  type    = "NS"
  ttl     = "300"
  records = aws_route53_zone.iron.name_servers
}

# Kubernetes Node DNS Records
resource "aws_route53_record" "k8s_node" {
  for_each = local.aws_nodes
  zone_id  = aws_route53_zone.private_iron.zone_id
  name     = each.key
  type     = "A"
  ttl      = "300"
  records  = [aws_instance.ec2_k8s_nodes[each.key].private_ip]
}

# Kubernetes API Load Balancer DNS Record (for now just points to control nodes)
resource "aws_route53_record" "k8s_api_1" {
  zone_id = aws_route53_zone.iron.zone_id
  name    = join(".", ["api", local.dns_iron])
  type    = "CNAME"
  ttl     = "300"
  records = [
    #aws_route53_record.k8s_node["c1"].name,
    # aws_instance.ec2_k8s_nodes["c1"].public_ip,
    # aws_instance.ec2_ansible.public_ip,
    aws_lb.kube_api.dns_name,
  ]
  # set_identifier = "api-1"
  # weighted_routing_policy {
  #   weight = 50
  # }
}

# resource "aws_route53_record" "k8s_api_2" {
#   zone_id = aws_route53_zone.iron.zone_id
#   name    = join(".", ["api", local.dns_iron])
#   type    = "CNAME"
#   ttl     = "300"
#   records = [
#     aws_route53_record.k8s_control2.name,
#   ]
#   set_identifier = "api-2"
#   weighted_routing_policy {
#     weight = 50
#   }
# }


