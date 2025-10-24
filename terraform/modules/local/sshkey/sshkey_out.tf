output "aws_key_pair_name" {
  value = aws_key_pair.this.key_name
}

output "ssh_private_key" {
  value = tls_private_key.this.private_key_openssh
}

output "ssh_public_key" {
  value = tls_private_key.this.public_key_openssh
}

output "tls_private_key" {
  value = tls_private_key.this
}

output "aws_secret_list" {
  description = "the aws secret created is [0] if it exists"
  value       = aws_secretsmanager_secret.this
}
