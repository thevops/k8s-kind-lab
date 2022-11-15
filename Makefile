.ONESHELL:
SHELL:=/bin/bash

# more colors
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
# https://stackoverflow.com/a/28938235
BOLD_GREEN=\033[1;32m
BOLD_RED=\033[1;31m
BOLD_BLUE=\033[1;34m
BOLD_YELLOW=\033[1;33m
END=\033[0m

define print_success
 @echo -e "$(BOLD_GREEN)[ $(1) ]$(END)"
endef

define print_info
 @echo -e "$(BOLD_BLUE)[ $(1) ]$(END)"
endef

define print_warning
 @echo -e "$(BOLD_YELLOW)[ $(1) ]$(END)"
endef

define print_error
 @echo -e "$(BOLD_RED)[ $(1) ]$(END)"
endef


############
# Templates
############

.PHONY: _destroy-cluster
_destroy-cluster: ## Destroy Kind cluster
	$(call print_info,Clean up...)
	cd live/kind/infrastructure/
	terraform apply -destroy -auto-approve || true
	rm -rf main-config .terraform/ .terraform.lock.hcl terraform.tfstate*
	cd ../../../

.PHONY: _init-cluster
_init-cluster:
	cd live/kind/infrastructure/
	$(call print_info,Lanuch Kind cluster...)
	terraform init
	terraform apply -auto-approve
	sleep 5
	cd ../../../

.PHONY: _install-argocd
_install-argocd:
	$(call print_info,Install/update ArgoCD Helm repository...)
	helm repo add argo-cd https://argoproj.github.io/argo-helm || helm repo update argo-cd
	helm dep update charts/argo/argocd/
	$(call print_info,Install ArgoCD CRDs...)
	kubectl apply -f charts/argo/argocd-crds/
	$(call print_info,Install ArgoCD...)
	kubectl create namespace argocd
	helm install argocd charts/argo/argocd/ --namespace argocd --wait --debug
	$(call print_info,Clean up local ArgoCD...)
	rm charts/argo/argocd/Chart.lock
	rm -r charts/argo/argocd/charts/


# K8s secret encoded with base64, because of Makefile issues
.PHONY: _install-repo-secret
_install-repo-secret:
	echo "YXBpVmVyc2lvbjogdjEKa2luZDogU2VjcmV0Cm1ldGFkYXRhOgogIG5hbWU6IHJlcG8ta2luZC1hcmdvLWRlbW8KICBuYW1lc3BhY2U6IGFyZ29jZAogIGxhYmVsczoKICAgIGFyZ29jZC5hcmdvcHJvai5pby9zZWNyZXQtdHlwZTogcmVwb3NpdG9yeQpzdHJpbmdEYXRhOgogIHR5cGU6IGdpdAogIHVybDogZ2l0QGdpdGh1Yi5jb206bmV0Z3VydS9raW5kLWFyZ28tZGVtby5naXQKICBzc2hQcml2YXRlS2V5OiB8CiAgICAtLS0tLUJFR0lOIE9QRU5TU0ggUFJJVkFURSBLRVktLS0tLQogICAgYjNCbGJuTnphQzFyWlhrdGRqRUFBQUFBQkc1dmJtVUFBQUFFYm05dVpRQUFBQUFBQUFBQkFBQUFNd0FBQUF0emMyZ3RaVwogICAgUXlOVFV4T1FBQUFDQlRQUmtnMGkzbldieVpiNHV4THNrU2Ntd29TRS9SYjVXMGdtcU5BUWJwV0FBQUFKanNad2d2N0djSQogICAgTHdBQUFBdHpjMmd0WldReU5UVXhPUUFBQUNCVFBSa2cwaTNuV2J5WmI0dXhMc2tTY213b1NFL1JiNVcwZ21xTkFRYnBXQQogICAgQUFBRUFuUWlJWlRxL3RVeFRvU3NrZmJ1SVh2NXNvT25RZnovR3RPSWg0c0g1V2QxTTlHU0RTTGVkWnZKbHZpN0V1eVJKeQogICAgYkNoSVQ5RnZsYlNDYW8wQkJ1bFlBQUFBRTJGeVoyOWpaRUJyYVc1a0xtTnNkWE4wWlhJQkFnPT0KICAgIC0tLS0tRU5EIE9QRU5TU0ggUFJJVkFURSBLRVktLS0tLQo=" | base64 -d | kubectl create -f -

.PHONY: _install-argocd-root-app
_install-argocd-root-app:
	$(call print_info,Install ArgoCD root application...)
	kubectl apply --namespace argocd -f live/kind/apps/templates/root.yaml
	$(call print_info,Remove Helm management for ArgoCD...)
	kubectl delete secret -l owner=helm,name=argocd -n argocd

############
# Targets
############

.PHONY: init-from-zero
init-from-zero: _destroy-cluster _init-cluster _install-argocd _install-argocd _install-repo-secret _install-argocd-root-app ## Init Kind cluster from zero

.PHONY: argocd-dashboard
argocd-dashboard: ## Port-forward ArgoCD dashboard
	$(call print_info,Get ArgoCD password...)
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo
	$(call print_info,Port-forward ArgoCD dashboard...)
	kubectl -n argocd port-forward svc/argocd-server 8080:443


.PHONY: kube-dashboard-token
kube-dashboard-token: # Kubernetes dashboard using token #
	@kubectl -n kubernetes-dashboard get secret $$(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
	echo
	$(call print_success,Open this URL: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/)
	kubectl proxy


# ----
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\t\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
