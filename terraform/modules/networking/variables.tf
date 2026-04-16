variable "cluster_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key content — used to CREATE a new keypair. Mutually exclusive with existing_keypair_name."
  default     = ""
}

variable "existing_keypair_name" {
  type        = string
  description = "Name of a pre-existing OTC keypair to REFERENCE. Mutually exclusive with ssh_public_key."
  default     = ""
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Provision an OTC NAT Gateway for outbound internet (~€30/mo)"
  default     = true
}

variable "nat_gateway_spec" {
  type        = string
  description = "NAT Gateway spec: 1=small (10k sessions), 2=medium (50k), 3=large (200k), 4=xlarge (1m)"
  default     = "1"
  validation {
    condition     = contains(["1", "2", "3", "4"], var.nat_gateway_spec)
    error_message = "nat_gateway_spec must be 1, 2, 3, or 4"
  }
}
