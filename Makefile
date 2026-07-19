NAME := edge-gateway
MINIKUBE := minikube
KUBECTL := kubectl

start:
	@echo "Starting edge-gateway local cluster..."
	$(MINIKUBE) start -p $(NAME) --memory=10240 --cpus=4 --driver=docker

start-argocd:
	@echo "Staring argocd"
	$(MINIKUBE) service argocd-server -n argocd

argocd-port-forward:
	kubectl port-forward svc/argocd-server \
		-n argocd \
		8888:443
		
argocd-password:
	kubectl -n argocd get secret argocd-initial-admin-secret \
		-o jsonpath="{.data.password}" | base64 --decode