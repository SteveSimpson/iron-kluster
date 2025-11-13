# this registers the private DNS name for access from the config bastion

resource "aws_route53_record" "haproxy_hosts" {
  count  = length(var.public_subnet_ids)
  zone_id  = var.dns_private_zone_id
  name     = "haproxy-${count.index + 1}"
  type     = "A"
  ttl      = "300"
  records  = [aws_instance.ec2_haproxy[count.index].private_ip]
}

resource "aws_route53_record" "haproxy_public" {
  zone_id  = var.dns_public_zone_id
  name     = var.dns_public_name
  type     = "A"
  ttl      = "300"
  records  = [aws_eip.haproxy_vip.public_ip]
}

