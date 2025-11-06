variable "dns_hostname" {
  description = "DNS hostname for NLB"
  type        = string
  default     = "api"
}

variable "dns_zone_id" {
  description = "Zone ID for DNS"
  type        = string
}

# variable "k8s_nodes" {
#   description = "K8s Node objects"
#   type = map(object({
#     instance_type   = string
#     key_name        = string
#     subnet_id       = string
#     id              = string
#     security_groups = list(string)
#     tags            = map(string)
#   }))
# }

variable "control_node_count" {
  description = "Count of control nodes"
  type        = number
  default     = 0
} 

variable "control_node_ids" {
  description = "List of control node instance IDs"
  type        = list(string)
  default     = []
} 

variable "k8s_public_subnet_list" {
  description = "Public subnet ID list for k8s"
  type        = list(string)
  default     = []
}

variable "k8s_security_groups" {
  description = "List of security group IDs of k8s"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "value"
  type        = string
}
