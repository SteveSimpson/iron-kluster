variable "ami_id" {
  description = "The AMI ID to use for the instances"
  type        = string
  default     = "ami-07a0f7780a01d9a56" # Ubuntu Server 24.04 LTS (HVM), amd64 SSD Volume Type, us-east-1
  # https://cloud-images.ubuntu.com/locator/ec2/
}

variable "ami_user" {
  description = "The root user for the ami"
  type        = string
  default     = "ubuntu"
}

variable "az1" {
  description = "The availability zone 1 on AWS"
  type        = string
  default     = "us-east-1a"
}

variable "az2" {
  description = "The availability zone 2 on AWS"
  type        = string
  default     = "us-east-1b"
}

variable "az3" {
  description = "The availability zone 3 on AWS"
  type        = string
  default     = "us-east-1c"
}

variable "dns_private_sub" {
  description = "The internal (private) subdomain"
  type        = string
  default     = "iron-private"
}

variable "dns_public_sub" {
  description = "The public subdomain"
  type        = string
  default     = "iron"
}

variable "dns_tld" {
  description = "The top level domain for the DNS zone (must be registered in Route 53)"
  type        = string
  default     = "lcsas.net"
}

variable "region" {
  description = "The region zone on AWS"
  type        = string
  default     = "us-east-1"
}


