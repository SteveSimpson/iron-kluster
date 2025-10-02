locals {
  dns_tld  = "lcsas.net"
  dns_iron = join(".", ["iron", local.dns_tld])
}

data "aws_route53_zone" "tld" {
  name         = local.dns_tld
  private_zone = false
}

resource "aws_route53_zone" "iron" {
  name = local.dns_iron

  tags = {
    Name = "Iron Kluster DNS Zone"
  }
}

resource "aws_route53_record" "iron_ns" {
  zone_id = data.aws_route53_zone.tld.zone_id
  name    = local.dns_iron
  type    = "NS"
  ttl     = "300"
  records = aws_route53_zone.iron.name_servers
}

resource "aws_route53_record" "k8s_control1" {
  zone_id = aws_route53_zone.iron.zone_id
  name    = join(".", ["c1", local.dns_iron])
  type    = "A"
  ttl     = "300"
  records = [
    aws_instance.ec2_control_az1.public_ip,
  ]
}


resource "aws_route53_record" "k8s_control2" {
  zone_id = aws_route53_zone.iron.zone_id
  name    = join(".", ["c2", local.dns_iron])
  type    = "A"
  ttl     = "300"
  records = [
    aws_instance.ec2_control_az2.public_ip,
  ]
}

resource "aws_route53_record" "k8s_worker1" {
  zone_id = aws_route53_zone.iron.zone_id
  count   = length(aws_instance.ec2_worker_az1)
  name    = join(".", [join("-", ["w1", count.index]), local.dns_iron])
  type    = "A"
  ttl     = "300"
  records = [
    aws_instance.ec2_worker_az1[count.index].public_ip,
  ]
}

resource "aws_route53_record" "k8s_worker2" {
  zone_id = aws_route53_zone.iron.zone_id
  count   = length(aws_instance.ec2_worker_az1)
  name    = join(".", [join("-", ["w2", count.index]), local.dns_iron])
  type    = "A"
  ttl     = "300"
  records = [
    aws_instance.ec2_worker_az2[count.index].public_ip,
  ]
}

# Kubernetes API Load Balancer DNS Record (for now just points to control nodes)
resource "aws_route53_record" "k8s_api_1" {
  zone_id = aws_route53_zone.iron.zone_id
  name    = join(".", ["api", local.dns_iron])
  type    = "CNAME"
  ttl     = "300"
  records = [
    aws_route53_record.k8s_control1.name,
  ]
  set_identifier = "api-1"
  weighted_routing_policy {
    weight = 50
  }
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
