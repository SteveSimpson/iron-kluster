# output "bastion_public_ip" {
#   value = module.iron_bastion.bastion_public_ip
# }

# output "haproxy_public_ips" {
#   value = module.haproxy.haproxy_public_ips
# } 

output "haproxy_vip" {
  value = module.haproxy.haproxy_vip
}

output "haproxy_vip_id" {
  value = module.haproxy.haproxy_vip_id
}

