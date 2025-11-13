locals {
  private_zone = join("-", [var.dns_public_sub, "private"])

  dns_iron         = join(".", [var.dns_public_sub, var.dns_tld])
  dns_iron_private = join(".", [local.private_zone, var.dns_tld])
}

data "aws_route53_zone" "tld" {
  name = var.dns_tld
}

# Iron Public Zone
resource "aws_route53_zone" "iron" {
  name          = local.dns_iron
  force_destroy = true

  tags = {
    Name = "Iron Kluster Public DNS Zone"
  }
}

# Iron Private Zone
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

# NS Pointer er Iron Public Zone
resource "aws_route53_record" "iron_ns" {
  zone_id = data.aws_route53_zone.tld.zone_id
  name    = local.dns_iron
  type    = "NS"
  ttl     = "300"
  records = aws_route53_zone.iron.name_servers
}

# NS Pointer er Iron Private Zone
resource "aws_route53_record" "private_iron_ns" {
  zone_id = data.aws_route53_zone.tld.zone_id
  name    = local.private_zone
  type    = "NS"
  ttl     = "300"
  records = aws_route53_zone.iron.name_servers
}


