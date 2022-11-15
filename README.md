# Kubernetes Lab

## Setup

Create cluster
```bash
make init-from-zero
```

Further deploy of rest applications is done by ArgoCD. They are configured to be installed after manual trigger in ArgoCD. Open ArgoCD UI with `make argocd-dashboard` and install them.


### For private ArgoCD repositry
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
  url: https://github.com/thevops/k8s-kind-lab.git
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
    -----END OPENSSH PRIVATE KEY-----
```

Change repository format from `https://github.com` to `git@github.com:`


## Endpoints

- `http://argocd.127.0.0.1.nip.io/` - ArgoCD (accessible after deploying ingress)
- `http://dashboard.127.0.0.1.nip.io/` - Kubernetes dashboard

## Screenshots

Todo
