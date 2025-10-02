locals {
  region = "us-east-1"
  az1    = "${local.region}a"
  az2    = "${local.region}b"

  # Get the entire file content from the http data source
  github_keys = data.http.github_key_file.body

  # Split the content into a list of lines using the newline character as a delimiter
  github_keys_lines = split("\n", local.github_keys)

  # Get the 2ns line from the list
  github_key = local.github_keys_lines[1]
  # github_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDyWW6zfSj5Yfx66WpRaxXwEOEill1wngdAjbqHGp4Oq steve@simpson.red"
}

provider "aws" {
  region = local.region
}

terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }
  }
}

data "http" "github_key_file" {
  # Replace this URL with the URL of your target web file
  url = "https://github.com/stevesimpson.keys"
}

resource "aws_key_pair" "my_key" {
  key_name   = "my-ssh-key"
  public_key = local.github_key
}
