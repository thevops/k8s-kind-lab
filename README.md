# kind-argo-demo

![screenshot](./docs/screenshot.png)

## First setup

Create cluster
```bash
cd live/kind/infrastructure/
# optional clean up
rm -rf main-config .terraform/ .terraform.lock.hcl terraform.tfstate*
# ---
terraform init
terraform apply
```

Install Argo CD (manual step)
```bash
cd ../../../ # back to root dir
helm repo add argo-cd https://argoproj.github.io/argo-helm
helm dep update charts/argo-cd/ # we need Chart.lock file for further installation

# install ArgoCD
kubectl create namespace argocd
helm install argocd charts/argo/argo-cd/ --namespace argocd --wait --debug

# access ArgoCD UI
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

> Below steps will install all applications


## First applications apply order:

1. root.yaml
2. argocd.yaml
3. argocd-crds.yaml
4. bitnami-sealed-secrets.yaml
5. ingress-nginx.yaml
6. example-echo-app.yaml

> Make sure that applications not applied should be commented out (whole code in their files). Uncomment and push them one by one.



Configure access to Github via SSH key
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: repo-kind-argo-demo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: git@github.com:thevops/k8s-kind-lab.git
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACBTPRkg0i3nWbyZb4uxLskScmwoSE/Rb5W0gmqNAQbpWAAAAJjsZwgv7GcI
    LwAAAAtzc2gtZWQyNTUxOQAAACBTPRkg0i3nWbyZb4uxLskScmwoSE/Rb5W0gmqNAQbpWA
    AAAEAnQiIZTq/tUxToSskfbuIXv5soOnQfz/GtOIh4sH5Wd1M9GSDSLedZvJlvi7EuyRJy
    bChIT9FvlbSCao0BBulYAAAAE2FyZ29jZEBraW5kLmNsdXN0ZXIBAg==
    -----END OPENSSH PRIVATE KEY-----
```


```bash
# install root app
kubectl apply --namespace argocd -f live/kind/apps/templates/root.yaml

# delete Helm management for ArgoCD
kubectl delete secret -l owner=helm,name=argocd -n argocd

# uncomment and push rest of apps one by one
# ...
```
