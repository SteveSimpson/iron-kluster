
variable "region" {
  description = "The region zone on AWS"
  default     = "us-east-1"
}

variable "az1" {
  description = "The availability zone 1 on AWS"
  default     = "us-east-1a"
}

variable "az2" {
  description = "The availability zone 2 on AWS"
  default     = "us-east-1b"
}

variable "workers_per_az" {
  description = "The number of worker nodes per availability zone"
  default     = 1
}

variable "ami_id" {
  description = "The AMI ID to use for the instances"
  default     = "ami-07a0f7780a01d9a56" # Ubuntu Server 24.04 LTS (HVM), amd64 SSD Volume Type, us-east-1
  # https://cloud-images.ubuntu.com/locator/ec2/
}
