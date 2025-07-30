variable "workload" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet" {
  type = string
}

variable "az" {
  type = string
}

variable "allow_ssh" {
  type = list(string)
  description = "List of CIDR blocks to allow SSH access"
  default = []
}
