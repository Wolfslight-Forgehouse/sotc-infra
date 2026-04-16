# Rancher Managed — Networking Only

Provision the OTC networking layer (VPC, subnet, security groups) that Rancher's node driver needs to create VMs.

## When to Use

- You're using Rancher Manager to create clusters via the KubeOVN cluster template
- The [sotc-platform](https://github.com/Wolfslight-Forgehouse/sotc-platform) cluster template needs pre-existing OTC networking resources

## Flow

```
1. terraform apply (this entrypoint)    → VPC, Subnet, Security Groups
2. Copy terraform output IDs
3. Rancher UI → Create Cluster          → Paste IDs into template form
4. Rancher provisions VMs via OTC node driver
5. RKE2 + KubeOVN + CCM auto-deployed via ManagedCharts
```

## Quick Start

```bash
cd environments/rancher-managed/
cp terraform.tfvars.example terraform.tfvars
# Edit with your OTC credentials

terraform init
terraform apply

# Copy the output for the Rancher template form:
terraform output rancher_template_inputs
```

## Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `access_key` | yes | OTC Access Key |
| `secret_key` | yes | OTC Secret Key |
| `cluster_name` | no | Resource name prefix (default: `rke2-rancher`) |
| `vpc_cidr` | no | VPC CIDR (default: `10.0.0.0/16`) |
| `subnet_cidr` | no | Subnet CIDR (default: `10.0.1.0/24`) |
| `ssh_public_key` | yes | SSH public key (registered as OTC keypair) |

## Outputs

The outputs map directly to the Rancher cluster template form fields:

| Output | Template Section | Field |
|--------|-----------------|-------|
| `vpc_id` | OTC Infrastructure | VPC ID |
| `subnet_id` | OTC Infrastructure | Subnet ID |
| `security_group_id` | OTC Infrastructure | Security Groups |
| `subnet_network_id` | Cloud Controller Manager | ELB Network ID |
| `keypair_name` | — | Used by OTC node driver |

Run `terraform output rancher_template_inputs` for a formatted summary.
