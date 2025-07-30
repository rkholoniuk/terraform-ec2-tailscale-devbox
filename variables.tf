variable "aws_region" {
  type    = string
}
variable "workload" {
  type        = string
  description = "Workload name (used in resource naming)"
  default     = "dev"
}
variable "rds_instance_class" {
  description = "Instance class for RDS (e.g. db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = false
}
variable "rds_username" {
  type = string
  description = "Username for RDS database"
  default = "admin"
}

variable "rds_password" {
  type      = string
  sensitive = true
  description = "Password for RDS database"
}

variable "allow_ssh" {
  type        = list(string)
  description = "Allow SSH access to the devbox"
}

variable "enable_rds" {
  description = "Whether to enable the RDS MySQL module"
  type        = bool
  default     = false
}