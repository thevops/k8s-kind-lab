# Kiali for Istio visualization

source: https://kiali.io/docs/installation/installation-guide/install-with-helm/



```
# ---
# using Helm - not working
# apiVersion: argoproj.io/v1alpha1
# kind: Application
# metadata:
#   name: kiali
#   namespace: argocd
#   finalizers:
#   - resources-finalizer.argocd.argoproj.io
# spec:
#   destination:
#     server: https://kubernetes.default.svc
#     namespace: istio-system
#   project: default
#   source:
#     path: manifests/istio/kiali-helm
#     repoURL: https://github.com/thevops/k8s-kind-lab.git
#     targetRevision: master
# #   syncPolicy:
# #     automated:
# #       prune: true
# #       selfHeal: true
```
