# sotc-infra

Infrastructure provisioning for RKE2 Kubernetes clusters on Swiss Open Telekom Cloud (OTC).

Supports three deployment cases through shared Terraform modules with case-specific entrypoints.

## Deployment Cases

| Case | Entrypoint | Description |
|------|-----------|-------------|
| **Full Terraform** | `terraform/environments/full-terraform/` | Greenfield: VPC + NAT Gateway + VMs + RKE2 bootstrap |
| **Demo (Legacy)** | `terraform/environments/demo/` | Simplified variant — no NAT Gateway, older cloud-init |
| **Join Existing** | `environments/join-existing/` | Pre-deployed VMs: RKE2 config + join via SSH |
| **Rancher Managed** | `environments/rancher-managed/` | Networking only — Rancher creates VMs via node driver |

## Default Configuration

- **CNI:** Cilium with kube-proxy replacement (MTU 1450 for VXLAN overhead)
- **Ingress:** Traefik (deployed from [sotc-platform](https://github.com/Wolfslight-Forgehouse/sotc-platform))
  — `rke2-ingress-nginx` is **disabled by default** (ingress-nginx maintenance has slowed)
- **Outbound:** NAT Gateway + Elastic IP — workers without Floating IPs still reach the internet
- **Storage:** EVS block (via Cinder CSI) + OBS object (via CSI-S3/GeeseFS)

## Related Repositories

| Repository | Purpose |
|-----------|---------|
| [sotc-cloud-manager](https://github.com/Wolfslight-Forgehouse/sotc-cloud-manager) | OTC Cloud Controller Manager |
| [sotc-platform](https://github.com/Wolfslight-Forgehouse/sotc-platform) | Kubernetes platform (Rancher templates, ArgoCD, policies) |

## Architecture

See [ADR-001](https://github.com/Wolfslight-Forgehouse/sotc-platform/blob/main/docs/ADR-001-REPO-ARCHITECTURE.md) for the repository split rationale.

---

## How-To: Deploy a Cluster (Full Terraform)

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Terraform | >= 1.7 | [terraform.io](https://www.terraform.io/downloads) |
| SSH key pair | — | Registered in OTC ECS console |
| OTC AK/SK | — | See [Credentials Setup](#credentials-setup) |

### OTC Services Required

All services are available by default in eu-ch2:
- **ECS** — Elastic Cloud Server (VMs)
- **VPC** — Virtual Private Cloud (networking)
- **EVS** — Elastic Volume Service (block storage)
- **ELB v3** — Elastic Load Balancer
- **OBS** — Object Storage (Terraform state backend)
- **IAM** — Identity and Access Management

### Step 1: Clone and Configure

```bash
git clone https://github.com/Wolfslight-Forgehouse/sotc-infra.git
cd sotc-infra/terraform/environments/demo

# Copy example vars
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
# OTC Authentication (AK/SK)
access_key  = "AK..."
secret_key  = "SK..."
project_id  = "your-project-uuid"

# SSH
ssh_public_key = "ssh-rsa AAAA..."

# RKE2
rke2_token = "a-secure-random-token"

# Optional
cluster_name   = "rke2-demo"
worker_count   = 2
master_flavor  = "s3.xlarge.4"    # 4 vCPU, 16 GB
worker_flavor  = "s3.large.4"     # 2 vCPU, 8 GB
```

### Step 2: Initialize and Apply

```bash
# Initialize with OBS backend
terraform init \
  -backend-config="bucket=your-tfstate-bucket" \
  -backend-config="access_key=AK..." \
  -backend-config="secret_key=SK..."

# Review the plan
terraform plan

# Deploy (creates VPC, SGs, VMs, RKE2 cluster)
terraform apply
```

**This provisions:**
- 1x VPC (10.0.0.0/16) with subnet (10.0.1.0/24)
- Security groups (API 6443, supervisor 9345, Geneve 6081, etc.)
- 1x Bastion host (jump server with public IP)
- 1x Control-plane node (s3.xlarge.4)
- 2x Worker nodes (s3.large.4)
- RKE2 server + agents via cloud-init

### Step 3: Access the Cluster

```bash
# Get outputs
terraform output

# SSH to master (via bastion)
BASTION=$(terraform output -raw bastion_ip)
MASTER=$(terraform output -raw master_ip)
ssh -J ubuntu@$BASTION ubuntu@$MASTER

# Fetch kubeconfig
ssh -J ubuntu@$BASTION ubuntu@$MASTER 'sudo cat /etc/rancher/rke2/rke2.yaml' > kubeconfig
# Replace 127.0.0.1 with master IP or set up an SSH tunnel:
ssh -L 6443:$MASTER:6443 -N ubuntu@$BASTION &
kubectl --kubeconfig=kubeconfig get nodes
```

### Step 4: Deploy Platform Components

After the cluster is running, deploy the platform stack from [sotc-platform](https://github.com/Wolfslight-Forgehouse/sotc-platform):
- OTC Cloud Controller Manager (ELB integration)
- KubeOVN or Cilium (CNI)
- ArgoCD, Monitoring, Policies

### Step 5: Destroy

```bash
# Remove LoadBalancer services first (prevents orphaned ELBs)
kubectl delete svc --all-namespaces -l spec.type=LoadBalancer

# Destroy infrastructure
terraform destroy
```

---

## How-To: Deploy via GitHub Actions

### Step 1: Configure GitHub Secrets

Navigate to **Settings → Secrets and variables → Actions**:

| Secret | Value | Where to Find |
|--------|-------|---------------|
| `OTC_ACCESS_KEY` | AK... | OTC Console → My Credentials → Access Keys |
| `OTC_SECRET_KEY` | SK... | Shown once at key creation |
| `OTC_PROJECT_ID` | Project UUID | OTC Console → My Credentials → Projects |
| `OTC_USERNAME` | IAM user | OTC Console → IAM → Users |
| `OTC_PASSWORD` | IAM password | OTC Console → IAM |
| `OTC_DOMAIN_NAME` | Domain/tenant name | OTC Console → My Credentials |
| `OBS_TFSTATE_BUCKET` | S3 bucket name | OTC Console → OBS → Buckets |
| `SSH_PRIVATE_KEY_B64` | base64-encoded SSH key | `base64 -w0 < ~/.ssh/rke2-key` |
| `SSH_PUBLIC_KEY` | Public key string | `cat ~/.ssh/rke2-key.pub` |
| `RKE2_TOKEN` | Random token | `openssl rand -hex 32` |
| `GHCR_PULL_TOKEN` | GitHub PAT | GitHub → Settings → Developer Settings |

### Step 2: Set CNI Variable

Navigate to **Settings → Secrets and variables → Actions → Variables**:

| Variable | Value | Description |
|----------|-------|-------------|
| `CNI_PLUGIN` | `kube-ovn` or `cilium` | Which CNI to deploy |

### Step 3: Run the Workflow

1. Go to **Actions → Terraform Apply**
2. Enter `APPLY` in the confirmation field
3. Click **Run workflow**
4. Monitor: Job 1 (Terraform ~5min) → Job 2 (Post-Apply ~15min)

The workflow provisions infrastructure AND deploys the full platform stack (CCM, CNI, ArgoCD, monitoring, storage, policies).

---

## Credentials Setup

### OTC Access Key / Secret Key

1. Log in to [OTC Console](https://console.otc.t-systems.com) (eu-ch2)
2. Click your username (top-right) → **My Credentials**
3. Go to **Access Keys** → **Create Access Key**
4. Download immediately — the Secret Key is shown only once

### OTC IAM Endpoint

For Swiss OTC (eu-ch2):
```
https://iam-pub.eu-ch2.sc.otc.t-systems.com/v3
```

> **Important:** Swiss OTC uses `iam-pub` (not `iam`) and the `.sc.` infix in the domain.

### SSH Key for Node Access

```bash
# Generate a key pair (if you don't have one)
ssh-keygen -t ed25519 -f ~/.ssh/rke2-key -N ""

# Register the public key in OTC Console → ECS → Key Pairs

# For GitHub Actions: base64-encode the private key
base64 -w0 < ~/.ssh/rke2-key  # → paste as SSH_PRIVATE_KEY_B64 secret
```

---

## Terraform Modules

| Module | Purpose | Used By |
|--------|---------|---------|
| `modules/compute` | ECS instances + cloud-init | Full Terraform |
| `modules/networking` | VPC, subnets, security groups | Full Terraform, Rancher Managed |
| `modules/rke2-cluster` | RKE2 server/agent provisioning | Full Terraform |
| `modules/jumpserver` | Bastion host with public IP | Full Terraform |
| `modules/dns` | OTC DNS zones + records | All cases |
| `modules/shared-elb` | Pre-provisioned ELB | Optional |
