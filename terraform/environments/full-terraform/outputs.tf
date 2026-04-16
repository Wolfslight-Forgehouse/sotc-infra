output "master_public_ip" {
  description = "Master node Floating IP — for SSH and kube-apiserver access"
  value       = opentelekomcloud_vpc_eip_v1.master.publicip[0].ip_address
}

output "master_private_ip" {
  description = "Master node internal IP (used by workers to join)"
  value       = module.compute.master_ip
}

output "worker_private_ips" {
  description = "Worker node internal IPs"
  value       = module.compute.worker_ips
}

output "nat_gateway_eip" {
  description = "NAT Gateway EIP (outbound traffic origin)"
  value       = module.networking.nat_eip
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "ssh_master" {
  description = "SSH command to access master"
  value       = "ssh ubuntu@${opentelekomcloud_vpc_eip_v1.master.publicip[0].ip_address}"
}

output "fetch_kubeconfig" {
  description = "Command to fetch kubeconfig from master (replaces 127.0.0.1 with Floating IP)"
  value       = "ssh ubuntu@${opentelekomcloud_vpc_eip_v1.master.publicip[0].ip_address} 'sudo cat /etc/rancher/rke2/rke2.yaml' | sed 's|127.0.0.1|${opentelekomcloud_vpc_eip_v1.master.publicip[0].ip_address}|g' > kubeconfig"
}
