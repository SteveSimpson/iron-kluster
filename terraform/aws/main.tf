locals {
  region = "us-east-1"
  az1    = "${local.region}a"
  az2    = "${local.region}b"
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
