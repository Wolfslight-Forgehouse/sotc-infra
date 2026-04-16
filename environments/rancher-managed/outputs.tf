# These outputs are the inputs for the Rancher Cluster Template
# (sotc-platform/rancher/cluster-templates/kubeovn-rke2/)

output "vpc_id" {
  description = "VPC ID — enter in Rancher template 'OTC Infrastructure' section"
  value       = module.networking.vpc_id
}

output "subnet_id" {
  description = "Subnet ID — enter in Rancher template 'OTC Infrastructure' section"
  value       = module.networking.subnet_id
}

output "subnet_network_id" {
  description = "Subnet Network ID — used for ELB configuration in Rancher template"
  value       = module.networking.subnet_network_id
}

output "security_group_id" {
  description = "Security Group ID — enter in Rancher template 'OTC Infrastructure' section"
  value       = module.networking.security_group_id
}

output "keypair_name" {
  description = "SSH keypair name registered in OTC — used by Rancher node driver"
  value       = module.networking.keypair_name
}

output "rancher_template_inputs" {
  description = "Copy-paste summary for the Rancher Cluster Template form"
  value       = <<-EOT

    ┌─────────────────────────────────────────────────────┐
    │  Rancher Cluster Template — OTC Infrastructure      │
    ├─────────────────────────────────────────────────────┤
    │  VPC ID:            ${module.networking.vpc_id}
    │  Subnet ID:         ${module.networking.subnet_id}
    │  Security Groups:   ${module.networking.security_group_id}
    │  Keypair Name:      ${module.networking.keypair_name}
    │                                                     │
    │  Cloud Controller Manager (ELB):                    │
    │  ELB Subnet ID:     ${module.networking.subnet_id}
    │  ELB Network ID:    ${module.networking.subnet_network_id}
    │  Floating Net ID:   (find via: openstack network list --external)
    └─────────────────────────────────────────────────────┘

  EOT
}
