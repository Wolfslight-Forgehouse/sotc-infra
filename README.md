# sotc-infra

Infrastructure provisioning for RKE2 Kubernetes clusters on Swiss Open Telekom Cloud (OTC).

Supports three deployment cases through shared Terraform modules with case-specific entrypoints.

## Deployment Cases

| Case | Entrypoint | Description |
|------|-----------|-------------|
| **Full Terraform** | `environments/full-terraform/` | Greenfield: VPC + VMs + RKE2 bootstrap |
| **Join Existing** | `environments/join-existing/` | Pre-deployed VMs: RKE2 config + join |
| **Rancher Managed** | `environments/rancher-managed/` | Networking only (Rancher creates VMs) |

## Related Repositories

| Repository | Purpose |
|-----------|---------|
| [sotc-cloud-manager](https://github.com/Wolfslight-Forgehouse/sotc-cloud-manager) | OTC Cloud Controller Manager |
| [sotc-platform](https://github.com/Wolfslight-Forgehouse/sotc-platform) | Kubernetes platform (Rancher templates, ArgoCD, policies) |

## Quick Start

```bash
cd environments/full-terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your OTC credentials
terraform init
terraform plan
terraform apply
```

## Architecture

See [ADR-001](https://github.com/Wolfslight-Forgehouse/sotc-platform/blob/main/docs/ADR/001-repo-architecture.md) for the repository split rationale.
