terraform {
  required_version = ">= 1.7"

  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = "~> 1.36"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "opentelekomcloud" {
  access_key  = var.access_key
  secret_key  = var.secret_key
  tenant_name = var.tenant_name
  tenant_id   = var.project_id
  region      = var.region
  auth_url    = "https://iam-pub.eu-ch2.sc.otc.t-systems.com/v3"
}

# ─────────────────────────────────────────────────────────
# Networking Layer
# - VPC + Subnet + Security Groups
# - NAT Gateway for outbound internet
# - SSH Keypair
# ─────────────────────────────────────────────────────────
module "networking" {
  source = "../../modules/networking"

  cluster_name          = var.cluster_name
  environment           = var.environment
  ssh_public_key        = var.ssh_public_key
  existing_keypair_name = var.existing_keypair_name
  enable_nat_gateway    = true
  nat_gateway_spec      = "1" # small: 10k concurrent sessions
}

# ─────────────────────────────────────────────────────────
# Compute Layer
# - 1 master + N workers with RKE2 cloud-init
# - Depends on networking for VPC/SG/keypair
# - NAT Gateway must be ready before VMs start (for rke2 install)
# ─────────────────────────────────────────────────────────
module "compute" {
  source = "../../modules/compute"

  cluster_name      = var.cluster_name
  environment       = var.environment
  subnet_id         = module.networking.subnet_id
  security_group_id = module.networking.security_group_id
  keypair_name      = module.networking.keypair_name
  ssh_key_hash      = module.networking.ssh_public_key_hash

  master_flavor = var.master_flavor
  worker_flavor = var.worker_flavor
  worker_count  = var.worker_count

  cluster_token       = var.cluster_token
  cni_plugin          = var.cni_plugin
  disabled_components = var.disabled_components
  obs_access_key      = var.obs_access_key
  obs_secret_key      = var.obs_secret_key

  # Ensure NAT is ready before VMs boot — cloud-init needs internet
  depends_on = [module.networking]
}

# ─────────────────────────────────────────────────────────
# Master Floating IP
# Gives SSH + kube-apiserver access to the master from outside the VPC.
# For production, replace with a dedicated bastion host.
# ─────────────────────────────────────────────────────────
resource "opentelekomcloud_vpc_eip_v1" "master" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.cluster_name}-master-eip"
    size        = 100
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "opentelekomcloud_compute_floatingip_associate_v2" "master" {
  floating_ip = opentelekomcloud_vpc_eip_v1.master.publicip[0].ip_address
  instance_id = module.compute.master_id
}
