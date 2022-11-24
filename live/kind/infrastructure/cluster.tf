resource "kind_cluster" "main" {
  name           = "main"
  node_image     = "kindest/node:v1.23.13"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    # allow insecure docker registry
    containerd_config_patches = [<<-TOML
[plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.127.0.0.1.nip.io"]
  endpoint = ["http://registry.127.0.0.1.nip.io"]
TOML
    ]

    node {
      role = "control-plane"

      kubeadm_config_patches = [<<-EOT
kind: InitConfiguration
nodeRegistration:
  kubeletExtraArgs:
    node-labels: "ingress-ready=true"
EOT
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }

    node {
      role = "worker"
    }
  }
}
