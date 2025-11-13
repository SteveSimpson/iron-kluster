variable "ami_id" {
  description = "The AMI ID to use for the instances"
  type        = string
}

variable "dns_private_zone_id" {
  description = "The ID of the private subdomain to register nodes in"
  type        = string
}

variable "dns_tld" {
  description = "The top level domain for the DNS zone (must be registered in Route 53)"
  type        = string
}

variable "k8s_nodes" {
  description = "K8s Node objects"
  type = map(object({
    instance_type   = string
    key_name        = string
    subnet_id       = string
    security_groups = list(string)
    tags            = map(string)
  }))
}

variable "local_state_path" {
  description = "Path for local secrets (set to '' to not create)"
  type        = string
  default     = "../../../../state_files"
}

variable "ssh_key_name" {
  description = "The name of the SSH key to access k8s hosts"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

