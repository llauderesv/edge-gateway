NAME := edge-gateway
MINIKUBE := minikube
KUBECTL := kubectl

start:
	@echo "Starting edge-gateway local cluster..."
	$(MINIKUBE) start -p $(NAME) --memory=10240 --cpus=4 --driver=docker

start-argocd:
	@echo "Staring argocd"
	$(MINIKUBE) service argocd-server -n argocd