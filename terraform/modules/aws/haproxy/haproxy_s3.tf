locals {
    haproxy_s3_bucket_name = "iron-haproxy-bucket"
}

resource "aws_s3_bucket" "haproxy_bucket" {
  bucket = local.haproxy_s3_bucket_name
  force_destroy = true
  object_lock_enabled = false

  tags = {
    Project     = "Iron K8s HAProxy"
  }
}

resource "aws_s3_bucket_public_access_block" "haproxy_bucket" {
  bucket = aws_s3_bucket.haproxy_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Keepalived secret for VRRP authentication - it only uses 8 characters
resource "random_password" "keepalived_secret" {
  length           = 8
  special          = false
}

resource "aws_s3_object" "keepalived_config" {
  count = length(var.public_subnet_ids)
  bucket = aws_s3_bucket.haproxy_bucket.id
  key    = join("/", [tostring(count.index), "keepalived.conf"])
  content = templatefile("${path.module}/templates/keepalived_conf.tmpl", {
    priority    = 101 - (2 * count.index) # 101 for master, 99 for backup, ...
    keepalived_secret = random_password.keepalived_secret.result
    virtual_ip = aws_eip.haproxy_vip.public_ip
    interface_name = var.ami_interface_id
    src_ip  = aws_instance.ec2_haproxy[count.index].private_ip
    # a list of all the peers except self
    peer_ips = join("\n", [for i, ip in aws_instance.ec2_haproxy[*].private_ip : "        ${ip}" if i != count.index])
  })
}

resource "aws_s3_object" "attach_eip_script" {
  count = length(var.public_subnet_ids)
  bucket = aws_s3_bucket.haproxy_bucket.id
  key    = join("/", [tostring(count.index), "attach_eip.sh"])
  content = templatefile("${path.module}/templates/attach_eip_sh.tmpl", {
    aws_region        = data.aws_region.current.region
    eip_allocation_id = aws_eip.haproxy_vip.allocation_id
    # interface_id      = aws_network_interface.public[count.index].id
    interface_id = aws_instance.ec2_haproxy[count.index].id
  })
}
