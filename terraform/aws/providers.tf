provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.3.0"
    }
  }
}
