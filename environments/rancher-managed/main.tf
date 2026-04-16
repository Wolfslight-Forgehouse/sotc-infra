terraform {
  required_version = ">= 1.7"

  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = "~> 1.36"
    }
  }
}

provider "opentelekomcloud" {
  access_key  = var.access_key
  secret_key  = var.secret_key
  domain_name = ""
  tenant_name = ""
  auth_url    = "https://iam-pub.eu-ch2.sc.otc.t-systems.com/v3"
  region      = var.region
}

# ── Networking (VPC + Subnet + Security Groups) ─────────
# This is all Rancher needs — it creates VMs via the OTC node driver.

module "networking" {
  source = "../../terraform/modules/networking"

  cluster_name   = var.cluster_name
  environment    = var.environment
  vpc_cidr       = var.vpc_cidr
  subnet_cidr    = var.subnet_cidr
  ssh_public_key = var.ssh_public_key
}
