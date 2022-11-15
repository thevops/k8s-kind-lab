# Kubernetes Lab

## Setup

Create cluster
```bash
make init-from-zero
```

Further deploy of rest applications is done by ArgoCD. They are configured to be installed after manual trigger in ArgoCD. Open ArgoCD UI with `make argocd-dashboard` and install them.


ArgoCD needs access to repository from which it pulls configuration. If this repository is private, then you have to add Kubernetes secret with SSH Key.

Example:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: repo-k8s-kind-lab
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: git@github.com:thevops/k8s-kind-lab.git
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
    -----END OPENSSH PRIVATE KEY-----
```


## Screenshots

Todo
