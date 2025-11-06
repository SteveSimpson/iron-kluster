variable "ami_id" {
  description = "The AMI ID to use for the instances"
  type        = string
}

variable "ami_user" {
  description = "The root user for the ami"
  type        = string
}

variable "az" {
  description = "The availability zone for the bastion on AWS"
  type        = string
}

variable "bastion_ssh_key_name" {
  description = "The name of the SSH key to access the basion host"
  type        = string
}

variable "bastion_ssh_private_key" {
  description = "The SSH key to access the basion host to upload files"
  type        = string
}

variable "bastion_security_group_ids" {
  description = "The security group IDs for the bastion host"
  type        = list(string)
}

variable "bastion_subnet_id" {
  description = "The subnet ID for the bastion host"
  type        = string
  
}

variable "haproxy_instances" {
  description = "HA Proxy EC2 instances"
}

variable "helm_dir" {
  description = "Directory path to the Helm Files"
  type        = string
}

variable "hostname" {
  description = "DNS hostname for bastion"
  type        = string
  default     = "config"
}

variable "instance_type" {
  description = "The instance type for the bastion host"
  type        = string
  default     = "t3.micro"
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

variable "k8s_private_dns" {
  description = "Private DNS domain for k8s nodes"
  type        = string
}

variable "k8s_ssh_key" {
  description = "The ssh private key to access k8s hosts"
  type        = string
}

variable "k8s_ssh_pubkey" {
  description = "The ssh public key to access k8s hosts"
  type        = string
}

variable "local_state_path" {
  description = "The path to state files for the bastion / ansible host"
  type        = string
}

variable "playbook_dir" {
  description = "Directory path to the Ansible Playbooks"
  type        = string
}

variable "public_dns_zone_id" {
  description = "The ID of the public subdomain to register bastion in"
  type        = string
} 

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
