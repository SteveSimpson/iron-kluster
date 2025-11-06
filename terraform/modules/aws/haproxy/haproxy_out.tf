# output "haproxy_public_ips" {
#   value = aws_instance.ec2_haproxy.*.public_ip
# }

output "haproxy_vip" {
  value = aws_eip.haproxy_vip.public_ip
}

output "haproxy_vip_id" {
  value = aws_eip.haproxy_vip.allocation_id
}

output "haproxy_instances" {
  value = aws_instance.ec2_haproxy
}
