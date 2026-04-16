terraform {
  required_version = ">= 1.7"
}

locals {
  first_master_ip    = var.master_ips[0]
  additional_masters = slice(var.master_ips, 1, length(var.master_ips))

  ssh_bastion_args = var.bastion_ip != "" ? "-o ProxyJump=${var.ssh_user}@${var.bastion_ip}" : ""

  # Render cloud-init templates for SSH delivery
  server_init_first = templatefile("${path.module}/../../cloud-init/rke2-server.yaml.tpl", {
    cluster_token = var.cluster_token
    cni_plugin    = var.cni_plugin
    tls_san       = local.first_master_ip
    server_url    = ""
    node_ip       = local.first_master_ip
  })

  agent_init = [for ip in var.worker_ips : templatefile("${path.module}/../../cloud-init/rke2-agent.yaml.tpl", {
    cluster_token = var.cluster_token
    master_ip     = local.first_master_ip
  })]
}

# ── Bootstrap first control-plane node ───────────────────────
resource "null_resource" "master_first" {
  connection {
    type                = "ssh"
    host                = local.first_master_ip
    user                = var.ssh_user
    private_key         = file(var.ssh_private_key_path)
    bastion_host        = var.bastion_ip != "" ? var.bastion_ip : null
    bastion_user        = var.bastion_ip != "" ? var.ssh_user : null
    bastion_private_key = var.bastion_ip != "" ? file(var.ssh_private_key_path) : null
    timeout             = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Installing RKE2 server on ${local.first_master_ip}...'",
      "curl -sfL https://get.rke2.io | sudo sh -",
      "sudo mkdir -p /etc/rancher/rke2",
      <<-CONFIG
      sudo tee /etc/rancher/rke2/config.yaml > /dev/null <<'EOF'
      token: ${var.cluster_token}
      cloud-provider-name: external
      ${var.cni_plugin == "kube-ovn" ? "cni: none" : "cni: cilium"}
      disable-kube-proxy: true
      tls-san:
        - ${local.first_master_ip}
      kube-apiserver-arg:
        - "anonymous-auth=false"
      EOF
      CONFIG
      ,
      <<-REG
      sudo tee /etc/rancher/rke2/registries.yaml > /dev/null <<'EOF'
      mirrors:
        registry.k8s.io:
          endpoint:
            - "https://registry.k8s.io"
        docker.io:
          endpoint:
            - "https://registry-1.docker.io"
      EOF
      REG
      ,
      "sudo chmod 600 /etc/rancher/rke2/config.yaml /etc/rancher/rke2/registries.yaml",
      "grep -q user_allow_other /etc/fuse.conf 2>/dev/null || echo user_allow_other | sudo tee -a /etc/fuse.conf",
      "sudo systemctl enable rke2-server.service",
      "sudo systemctl start rke2-server.service",
      "echo 'Waiting for RKE2 server to be ready...'",
      "for i in $(seq 1 60); do sudo systemctl is-active rke2-server && break; sleep 10; done",
      "echo 'RKE2 server ready on ${local.first_master_ip}'",
    ]
  }
}

# ── Join additional control-plane nodes ──────────────────────
resource "null_resource" "master_additional" {
  for_each = toset(local.additional_masters)

  depends_on = [null_resource.master_first]

  connection {
    type                = "ssh"
    host                = each.value
    user                = var.ssh_user
    private_key         = file(var.ssh_private_key_path)
    bastion_host        = var.bastion_ip != "" ? var.bastion_ip : null
    bastion_user        = var.bastion_ip != "" ? var.ssh_user : null
    bastion_private_key = var.bastion_ip != "" ? file(var.ssh_private_key_path) : null
    timeout             = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Joining control-plane node ${each.value}...'",
      "curl -sfL https://get.rke2.io | sudo sh -",
      "sudo mkdir -p /etc/rancher/rke2",
      <<-CONFIG
      sudo tee /etc/rancher/rke2/config.yaml > /dev/null <<'EOF'
      server: https://${local.first_master_ip}:9345
      token: ${var.cluster_token}
      cloud-provider-name: external
      ${var.cni_plugin == "kube-ovn" ? "cni: none" : "cni: cilium"}
      disable-kube-proxy: true
      tls-san:
        - ${each.value}
      EOF
      CONFIG
      ,
      "sudo chmod 600 /etc/rancher/rke2/config.yaml",
      "sudo systemctl enable rke2-server.service",
      "sudo systemctl start rke2-server.service",
      "for i in $(seq 1 60); do sudo systemctl is-active rke2-server && break; sleep 10; done",
      "echo 'Control-plane node ${each.value} joined'",
    ]
  }
}

# ── Join worker nodes ────────────────────────────────────────
resource "null_resource" "worker" {
  for_each = toset(var.worker_ips)

  depends_on = [null_resource.master_first]

  connection {
    type                = "ssh"
    host                = each.value
    user                = var.ssh_user
    private_key         = file(var.ssh_private_key_path)
    bastion_host        = var.bastion_ip != "" ? var.bastion_ip : null
    bastion_user        = var.bastion_ip != "" ? var.ssh_user : null
    bastion_private_key = var.bastion_ip != "" ? file(var.ssh_private_key_path) : null
    timeout             = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Joining worker node ${each.value}...'",
      "curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sudo sh -",
      "sudo mkdir -p /etc/rancher/rke2",
      <<-CONFIG
      sudo tee /etc/rancher/rke2/config.yaml > /dev/null <<'EOF'
      server: https://${local.first_master_ip}:9345
      token: ${var.cluster_token}
      cloud-provider-name: external
      EOF
      CONFIG
      ,
      <<-REG
      sudo tee /etc/rancher/rke2/registries.yaml > /dev/null <<'EOF'
      mirrors:
        registry.k8s.io:
          endpoint:
            - "https://registry.k8s.io"
        docker.io:
          endpoint:
            - "https://registry-1.docker.io"
      EOF
      REG
      ,
      "sudo chmod 600 /etc/rancher/rke2/config.yaml /etc/rancher/rke2/registries.yaml",
      "grep -q user_allow_other /etc/fuse.conf 2>/dev/null || echo user_allow_other | sudo tee -a /etc/fuse.conf",
      "sudo systemctl enable rke2-agent.service",
      "sudo systemctl start rke2-agent.service",
      "for i in $(seq 1 60); do sudo systemctl is-active rke2-agent && break; sleep 10; done",
      "echo 'Worker node ${each.value} joined'",
    ]
  }
}
