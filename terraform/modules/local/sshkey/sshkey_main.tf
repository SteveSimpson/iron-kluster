locals {
  private_key = join("/", [var.local_state_path, var.key_name])
  public_key  = join(".", [local.private_key, "pub"])
}

resource "tls_private_key" "this" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = tls_private_key.this.public_key_openssh
}

# for now store keys in state_files directory, for prod use AWS Secrets Manager
resource "local_file" "private_key_file" {
  count = var.local_state_path == "" ? 0 : 1

  content         = tls_private_key.this.private_key_openssh
  filename        = local.private_key
  file_permission = "0600"
}

resource "local_file" "public_key_file" {
  count = var.local_state_path == "" ? 0 : 1

  content         = tls_private_key.this.public_key_openssh
  filename        = local.public_key
  file_permission = "0644"
}

resource "aws_secretsmanager_secret" "this" {
  count = var.kms_key_arn_for_secret == "" ? 0 : 1

  name = var.key_name
}
