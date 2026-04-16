# Join Existing VMs

Bootstrap an RKE2 cluster on pre-deployed VMs via SSH. Terraform connects to each node, installs RKE2, writes the config, and starts the services.

## When to Use

- VMs already exist (provisioned manually, by another team, or different IaC)
- You have SSH access to all nodes (directly or via bastion)
- You want RKE2 without re-provisioning the VMs

## Prerequisites

- Ubuntu 22.04 VMs with:
  - Internet access (or HTTP proxy)
  - SSH enabled (port 22)
  - `sudo` without password for the SSH user
- Security group allowing: TCP 6443, 9345, 2379-2380, 10250, UDP 6081/8472
- SSH private key with access to all nodes

## Quick Start

```bash
cd environments/join-existing/
cp terraform.tfvars.example terraform.tfvars
# Edit with your node IPs and SSH key path

terraform init
terraform apply
```

## What It Does

```
1. SSH to first master → install RKE2 server → start
2. SSH to additional masters → install RKE2 server → join first master
3. SSH to workers → install RKE2 agent → join first master
```

## Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `master_ips` | yes | List of control-plane node IPs (first = initial server) |
| `worker_ips` | no | List of worker node IPs |
| `ssh_user` | no | SSH username (default: `ubuntu`) |
| `ssh_private_key_path` | yes | Path to SSH private key |
| `bastion_ip` | no | Bastion/jump host public IP (empty = direct SSH) |
| `cluster_token` | yes | Shared RKE2 cluster token |
| `cni_plugin` | no | `kube-ovn` (default) or `cilium` |

## After Apply

```bash
# Fetch kubeconfig
$(terraform output -raw kubeconfig_command) > kubeconfig
sed -i 's|127.0.0.1|MASTER_IP|g' kubeconfig
kubectl --kubeconfig=kubeconfig get nodes
```

Then deploy CNI and CCM from [sotc-platform](https://github.com/Wolfslight-Forgehouse/sotc-platform).
