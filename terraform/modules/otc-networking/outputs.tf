output "vpc_id" { value = opentelekomcloud_vpc_v1.main.id }
output "subnet_id" { value = opentelekomcloud_vpc_subnet_v1.main.id }
output "subnet_network_id" {
  description = "Neutron network ID (used for ELB backend and NAT SNAT rules)"
  value       = opentelekomcloud_vpc_subnet_v1.main.subnet_id
}
output "secgroup_id" { value = opentelekomcloud_networking_secgroup_v2.rke2.id }
output "nat_gateway_id" { value = opentelekomcloud_nat_gateway_v2.main.id }
output "nat_eip" { value = opentelekomcloud_vpc_eip_v1.nat.publicip[0].ip_address }
