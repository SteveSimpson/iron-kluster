output "bastion_public_ip" {
  value = aws_instance.ec2_ansible.public_ip
}
