variable "access_key" {
  type        = string
  sensitive   = true
  description = "OTC Access Key"
}

variable "secret_key" {
  type        = string
  sensitive   = true
  description = "OTC Secret Key"
}

variable "project_id" {
  type        = string
  description = "OTC Project ID (UUID)"
}

variable "tenant_name" {
  type        = string
  description = "OTC Tenant/Project Name (e.g. eu-ch2)"
}

variable "region" {
  type    = string
  default = "eu-ch2"
}

variable "cluster_name" {
  type    = string
  default = "rke2-full"
}

variable "environment" {
  type    = string
  default = "demo"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key — used to CREATE a new OTC keypair. Leave empty to use existing_keypair_name instead."
  default     = ""
}

variable "existing_keypair_name" {
  type        = string
  description = "Name of pre-existing OTC keypair. Leave empty to create a new one from ssh_public_key."
  default     = ""
}

variable "cluster_token" {
  type        = string
  sensitive   = true
  description = "RKE2 cluster token (shared secret for node join)"
}

variable "master_flavor" {
  type    = string
  default = "s3.xlarge.4"
}

variable "worker_flavor" {
  type    = string
  default = "s3.large.4"
}

variable "worker_count" {
  type    = number
  default = 2
}

variable "cni_plugin" {
  type        = string
  default     = "cilium"
  description = "CNI plugin: 'cilium' (built-in) or 'kube-ovn' (deployed later)"
}

# Optional OBS credentials for geesefs download (cloud-init)
variable "obs_access_key" {
  type      = string
  sensitive = true
  default   = ""
}

variable "obs_secret_key" {
  type      = string
  sensitive = true
  default   = ""
}
