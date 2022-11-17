# Kiali-server

Get token for auth:
```
kubectl get secret -n istio-system $(kubectl get sa kiali -n istio-system -o "jsonpath={.secrets[0].name}") -o jsonpath={.data.token} | base64 -d
```
