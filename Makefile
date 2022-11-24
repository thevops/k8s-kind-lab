.ONESHELL:
SHELL:=/bin/bash
.SILENT: # don't print commands before execute

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
	terraform apply -destroy -auto-approve
	rm -rvf main-config .terraform/ .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup

.PHONY: _init-cluster
_init-cluster:
	cd live/kind/infrastructure/
	$(call print_info,Lanuch Kind cluster...)
	terraform init
	terraform apply -auto-approve
	sleep 5

.PHONY: _install-argocd
_install-argocd:
	$(call print_info,Install/update ArgoCD Helm repository...)
	helm repo add argo-cd https://argoproj.github.io/argo-helm || helm repo update argo-cd
	helm dep update manifests/argo/argocd/
	$(call print_info,Install ArgoCD CRDs...)
	kubectl apply -f manifests/argo/argocd-crds/
	$(call print_info,Install ArgoCD...)
	kubectl create namespace argocd
	helm install argocd manifests/argo/argocd/ --namespace argocd --wait --debug
	$(call print_info,Clean up local ArgoCD...)
	rm -f manifests/argo/argocd/Chart.lock
	rm -rf manifests/argo/argocd/charts/


# K8s secret encoded with base64, because of Makefile issues
.PHONY: _install-repo-secret
_install-repo-secret:
	echo "SSH key for private repository encoded with base64" | base64 -d | kubectl create -f -

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
init-from-zero: _destroy-cluster _init-cluster _install-argocd _install-argocd-root-app # _install-repo-secret ## Init Kind cluster from zero

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
