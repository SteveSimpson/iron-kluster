variable "ami_id" {
  description = "The AMI ID to use for the instances"
  type        = string
  default = "ami-06e880a88a1e3ebd9" # ubuntu 24.04 ARM 64bit, US east-1
}

variable "ami_interface_id" {
  description = "The AMI ID to use for the instances"
  type        = string
  default     = "ens5" # base private interface on the ubuntu 24.04 AMI
}

# DNS zone so bastion can use DNS to resolve the internal IPs of the HAProxy hosts
variable "dns_private_zone_id" {
  description = "The ID of the private subdomain to register nodes in"
  type        = string
}

variable "dns_public_name" {
  description = "The public DNS name to register the HAProxy VIP under"
  type        = string
  default     = "api"
}

# DNS zone so bastion can use DNS to resolve the internal IPs of the HAProxy hosts
variable "dns_public_zone_id" {
  description = "The ID of the public domain/subdomain to register the host in"
  type        = string
}

variable "instance_type" {
  description = "The instance type for the HAProxy hosts"
  type        = string
  default     = "t4g.micro"
}

variable "private_subnet_ids" {
  description = "Subnet IDs where HAProxy instances will be deployed"
  type        = list(string) 
}

variable "public_subnet_ids" {
  description = "Subnet IDs where HAProxy instances will be deployed"
  type        = list(string) 
}

variable "ssh_key_name" {
  description = "The name of the SSH key to access HAProxy hosts"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where HAProxy instances will be deployed"
  type        = string
}
