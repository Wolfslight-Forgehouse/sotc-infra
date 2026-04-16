terraform {
  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = "~> 1.36"
    }
  }
}

resource "opentelekomcloud_vpc_v1" "main" {
  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr
}

resource "opentelekomcloud_vpc_subnet_v1" "main" {
  name       = "${var.cluster_name}-subnet"
  cidr       = var.subnet_cidr
  vpc_id     = opentelekomcloud_vpc_v1.main.id
  gateway_ip = cidrhost(var.subnet_cidr, 1)
  dns_list   = ["100.125.4.25", "8.8.8.8"]
}

# ─────────────────────────────────────────────────────────
# NAT Gateway + SNAT Rule + EIP
# Provides outbound internet for VMs without Floating IPs.
# OTC VPC subnets don't have automatic internet egress —
# a NAT Gateway is the production-standard solution.
# ─────────────────────────────────────────────────────────

resource "opentelekomcloud_vpc_eip_v1" "nat" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.cluster_name}-nat-eip"
    size        = 100
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "opentelekomcloud_nat_gateway_v2" "main" {
  name                = "${var.cluster_name}-nat"
  description         = "NAT Gateway for ${var.cluster_name} cluster outbound traffic"
  spec                = "1" # 1=small (10k sessions), 2=medium, 3=large, 4=xlarge
  router_id           = opentelekomcloud_vpc_v1.main.id
  internal_network_id = opentelekomcloud_vpc_subnet_v1.main.subnet_id
}

resource "opentelekomcloud_nat_snat_rule_v2" "main" {
  nat_gateway_id = opentelekomcloud_nat_gateway_v2.main.id
  network_id     = opentelekomcloud_vpc_subnet_v1.main.subnet_id
  floating_ip_id = opentelekomcloud_vpc_eip_v1.nat.id
}

resource "opentelekomcloud_networking_secgroup_v2" "rke2" {
  name        = "${var.cluster_name}-sg"
  description = "Security group for RKE2 cluster"
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "kube_api" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.rke2.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "rke2_supervisor" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9345
  port_range_max    = 9345
  remote_ip_prefix  = var.vpc_cidr
  security_group_id = opentelekomcloud_networking_secgroup_v2.rke2.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "etcd" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2379
  port_range_max    = 2380
  remote_ip_prefix  = var.vpc_cidr
  security_group_id = opentelekomcloud_networking_secgroup_v2.rke2.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "kubelet" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10250
  remote_ip_prefix  = var.vpc_cidr
  security_group_id = opentelekomcloud_networking_secgroup_v2.rke2.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "nodeport" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.rke2.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = opentelekomcloud_networking_secgroup_v2.rke2.id
}

resource "opentelekomcloud_networking_secgroup_rule_v2" "internal_all" {
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = var.vpc_cidr
  security_group_id = opentelekomcloud_networking_secgroup_v2.rke2.id
}
