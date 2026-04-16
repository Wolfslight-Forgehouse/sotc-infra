variable "cluster_name" {
  type        = string
  description = "Cluster name (used as prefix for VPC, subnet, SG resources)"
  default     = "rke2-rancher"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, production)"
  default     = "production"
}

variable "access_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "region" {
  type    = string
  default = "eu-ch2"
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
  description = "SSH public key — registered as OTC keypair for Rancher node driver"
}
