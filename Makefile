.PHONY: argocd-password,port-forward-gateway,port-forward-argocd

NAME := edge-gateway
MINIKUBE := minikube
KUBECTL := kubectl

start-cluster:
	@echo "Starting edge-gateway local cluster..."
	$(MINIKUBE) start -p $(NAME) --memory=10240 --cpus=4 --driver=docker

port-forward-argo:
	@echo "🚀 Argo CD UI open at https://localhost:9443"
	@kubectl port-forward -n argocd svc/argocd-server 9443:443
		
argocd-password:
	kubectl -n argocd get secret argocd-initial-admin-secret \
		-o jsonpath="{.data.password}" | base64 --decode

# Port-forward to the Envoy Gateway Proxy
port-forward-gateway:
	@echo "🔍 Finding proxy service for edge-gateway..."
	@SVC_NAME=$$(kubectl get svc -n envoy-gateway-system --selector=gateway.envoyproxy.io/owning-gateway-namespace=default,gateway.envoyproxy.io/owning-gateway-name=edge-gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -z "$$SVC_NAME" ]; then \
		echo "❌ Could not find service in envoy-gateway-system. Checking default namespace..."; \
		SVC_NAME=$$(kubectl get svc -n default --selector=gateway.envoyproxy.io/owning-gateway-namespace=default,gateway.envoyproxy.io/owning-gateway-name=edge-gateway -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	fi; \
	if [ -z "$$SVC_NAME" ]; then \
		echo "❌ Error: No proxy service found for Gateway 'edge-gateway'."; \
		exit 1; \
	fi; \
	echo "🚀 Port-forwarding to service/$$SVC_NAME on port 8888..."; \
	kubectl port-forward -n envoy-gateway-system service/$$SVC_NAME 8080:80