variable "key_name" {
  type    = string
  default = "default"
}

variable "kms_key_arn_for_secret" {
  description = "KMS Key ARN to store the KMS Private key in AWS (set to '' to not create)"
  type        = string
  default     = ""
}

variable "local_state_path" {
  description = "Path for local secrets (set to '' to not create)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
