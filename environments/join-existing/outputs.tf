output "master_ip" {
  description = "IP of the first (initial) control-plane node"
  value       = local.first_master_ip
}

output "kubeconfig_command" {
  description = "Command to fetch kubeconfig from the master node"
  value       = var.bastion_ip != "" ? "ssh -J ${var.ssh_user}@${var.bastion_ip} ${var.ssh_user}@${local.first_master_ip} 'sudo cat /etc/rancher/rke2/rke2.yaml'" : "ssh ${var.ssh_user}@${local.first_master_ip} 'sudo cat /etc/rancher/rke2/rke2.yaml'"
}

output "node_count" {
  description = "Total nodes in the cluster"
  value       = length(var.master_ips) + length(var.worker_ips)
}
