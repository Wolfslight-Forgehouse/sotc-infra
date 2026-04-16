variable "cluster_name" {
  type        = string
  description = "Cluster identifier (used in node names)"
  default     = "rke2"
}

variable "master_ips" {
  type        = list(string)
  description = "Internal IPs of pre-deployed control-plane nodes. First IP becomes the initial server."
}

variable "worker_ips" {
  type        = list(string)
  description = "Internal IPs of pre-deployed worker nodes"
  default     = []
}

variable "ssh_user" {
  type        = string
  description = "SSH username on the VMs"
  default     = "ubuntu"
}

variable "ssh_private_key_path" {
  type        = string
  description = "Path to SSH private key for node access"
}

variable "bastion_ip" {
  type        = string
  description = "Public IP of bastion/jump host. Leave empty for direct SSH."
  default     = ""
}

variable "cluster_token" {
  type        = string
  description = "Shared RKE2 token for cluster join (all nodes must use the same)"
  sensitive   = true
}

variable "cni_plugin" {
  type        = string
  description = "CNI plugin: 'cilium' (built-in) or 'kube-ovn' (deployed separately)"
  default     = "kube-ovn"
  validation {
    condition     = contains(["cilium", "kube-ovn"], var.cni_plugin)
    error_message = "cni_plugin must be 'cilium' or 'kube-ovn'."
  }
}
