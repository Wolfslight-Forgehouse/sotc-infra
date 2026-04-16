#cloud-config
# RKE2 Agent (Worker) Bootstrap
# Used by: join-existing (rendered locally, applied via SSH)

write_files:
  - path: /etc/rancher/rke2/config.yaml
    permissions: "0600"
    content: |
      server: https://${master_ip}:9345
      token: ${cluster_token}
      cloud-provider-name: external

  - path: /etc/rancher/rke2/registries.yaml
    permissions: "0600"
    content: |
      mirrors:
        registry.k8s.io:
          endpoint:
            - "https://registry.k8s.io"
        docker.io:
          endpoint:
            - "https://registry-1.docker.io"

  - path: /etc/fuse.conf
    append: true
    content: |
      user_allow_other

runcmd:
  - curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -
  - systemctl enable rke2-agent.service
  - systemctl start rke2-agent.service
