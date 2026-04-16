#cloud-config
# RKE2 Server (Control-Plane) Bootstrap
# Used by: join-existing (rendered locally, applied via SSH)

write_files:
  - path: /etc/rancher/rke2/config.yaml
    permissions: "0600"
    content: |
      token: ${cluster_token}
      cloud-provider-name: external
%{ if cni_plugin == "kube-ovn" ~}
      cni: none
      disable-kube-proxy: true
%{ else ~}
      cni: cilium
      disable-kube-proxy: true
%{ endif ~}
%{ if tls_san != "" ~}
      tls-san:
        - ${tls_san}
%{ endif ~}
%{ if server_url != "" ~}
      server: ${server_url}
%{ endif ~}
      kube-apiserver-arg:
        - "anonymous-auth=false"

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

%{ if cni_plugin == "cilium" ~}
  - path: /var/lib/rancher/rke2/server/manifests/rke2-cilium-config.yaml
    permissions: "0600"
    content: |
      apiVersion: helm.cattle.io/v1
      kind: HelmChartConfig
      metadata:
        name: rke2-cilium
        namespace: kube-system
      spec:
        valuesContent: |-
          kubeProxyReplacement: true
          k8sServiceHost: "${node_ip}"
          k8sServicePort: "6443"
          routingMode: tunnel
          tunnelProtocol: vxlan
          MTU: 1450
          hubble:
            enabled: true
            relay:
              enabled: true
%{ endif ~}

runcmd:
  - curl -sfL https://get.rke2.io | sh -
  - systemctl enable rke2-server.service
  - systemctl start rke2-server.service
