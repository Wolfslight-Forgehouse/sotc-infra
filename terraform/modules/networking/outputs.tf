output "vpc_id" {
  value = opentelekomcloud_vpc_v1.rke2.id
}

output "subnet_id" {
  value = opentelekomcloud_vpc_subnet_v1.rke2.id
}

output "subnet_network_id" {
  value = opentelekomcloud_vpc_subnet_v1.rke2.subnet_id
}

output "security_group_id" {
  value = opentelekomcloud_networking_secgroup_v2.rke2.id
}

output "network_id" {
  description = "Network ID (opentelekomcloud_vpc_subnet_v1.id) for NAT gateway"
  value       = opentelekomcloud_vpc_subnet_v1.rke2.id
}

output "keypair_name" {
  description = "Keypair name — either newly created or referenced from existing"
  value       = local.use_existing_keypair ? var.existing_keypair_name : opentelekomcloud_compute_keypair_v2.rke2[0].name
}

output "ssh_public_key_hash" {
  description = "Hash of SSH public key (triggers VM recreation on key change). Empty when using existing keypair."
  value       = local.use_existing_keypair ? "existing-keypair" : sha256(var.ssh_public_key)
}

output "nat_gateway_id" {
  description = "NAT Gateway ID (null if not enabled)"
  value       = var.enable_nat_gateway ? opentelekomcloud_nat_gateway_v2.main[0].id : null
}

output "nat_eip" {
  description = "NAT Gateway EIP address (null if not enabled)"
  value       = var.enable_nat_gateway ? opentelekomcloud_vpc_eip_v1.nat[0].publicip[0].ip_address : null
}
