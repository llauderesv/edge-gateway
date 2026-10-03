.PHONY: argocd-password port-forward-gateway port-forward-gateway-https port-forward-gateway-qa-https port-forward-gateway-prod-https port-forward-argo port-forward-envoy-stats port-forward-grafana port-forward-prometheus

NAME := edge-gateway
MINIKUBE := minikube
KUBECTL := kubectl
ENVOY_NAMESPACE := envoy-gateway-system
ENVOY_ADMIN_PORT := 19000
PROMETHEUS_NAMESPACE := monitoring
PROMETHEUS_SERVICE := monitoring-kube-prometheus-prometheus

start-cluster:
	@echo "Starting edge-gateway local cluster..."
	$(MINIKUBE) start -p $(NAME) --memory=10240 --cpus=4 --driver=docker

# Port-forward to the Argo CD UI
port-forward-argo:
	@echo "🚀 Argo CD UI open at https://localhost:9443"
	@kubectl port-forward -n argocd svc/argocd-server 9443:443
		
# Port-forward to the Envoy Gateway Proxy
port-forward-gateway:
	@echo "🔍 Finding proxy service for edge-gateway..."
	@SVC_NAME=$$(kubectl get svc -n envoy-gateway-system --selector=gateway.envoyproxy.io/owning-gateway-namespace=envoy-gateway-system,gateway.envoyproxy.io/owning-gateway-name=envoy-data-plane-dev -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -z "$$SVC_NAME" ]; then \
		echo "❌ Could not find service in envoy-gateway-system. Checking envoy-gateway-system namespace..."; \
		SVC_NAME=$$(kubectl get svc -n envoy-gateway-system --selector=gateway.envoyproxy.io/owning-gateway-namespace=envoy-gateway-system,gateway.envoyproxy.io/owning-gateway-name=envoy-data-plane-dev -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	fi; \
	if [ -z "$$SVC_NAME" ]; then \
		echo "❌ Error: No proxy service found for Gateway 'envoy-data-plane-dev'."; \
		exit 1; \
	fi; \
	echo "🚀 Port-forwarding to service/$$SVC_NAME on port 8888..."; \
	kubectl port-forward -n envoy-gateway-system service/$$SVC_NAME 8080:80

# Port-forward to the dev Envoy Gateway HTTPS listener
port-forward-gateway-https:
	@SVC_NAME=$$(kubectl get svc -n envoy-gateway-system --selector=gateway.envoyproxy.io/owning-gateway-namespace=envoy-gateway-system,gateway.envoyproxy.io/owning-gateway-name=envoy-data-plane-dev -o jsonpath='{.items[0].metadata.name}'); \
	if [ -z "$$SVC_NAME" ]; then echo "❌ Could not find the dev Gateway proxy service."; exit 1; fi; \
	HTTPS_PORT=$$(kubectl get svc -n envoy-gateway-system "$$SVC_NAME" -o jsonpath='{.spec.ports[?(@.port==443)].port}'); \
	if [ -z "$$HTTPS_PORT" ]; then \
		echo "❌ The live dev Gateway Service does not expose HTTPS port 443 yet."; \
		echo "   Sync the ApplicationSet after the localhost HTTPS listener change is available on its tracked Git revision."; \
		exit 1; \
	fi; \
	echo "🔒 Port-forwarding to service/$$SVC_NAME on https://localhost:8443..."; \
	kubectl port-forward -n envoy-gateway-system service/$$SVC_NAME 8443:443

# Port-forward to the QA Envoy Gateway HTTPS listener
port-forward-gateway-qa-https:
	@SVC_NAME=$$(kubectl get svc -n envoy-gateway-system --selector=gateway.envoyproxy.io/owning-gateway-namespace=envoy-gateway-system,gateway.envoyproxy.io/owning-gateway-name=envoy-data-plane-qa -o jsonpath='{.items[0].metadata.name}'); \
	if [ -z "$$SVC_NAME" ]; then echo "❌ Could not find the QA Gateway proxy service."; exit 1; fi; \
	HTTPS_PORT=$$(kubectl get svc -n envoy-gateway-system "$$SVC_NAME" -o jsonpath='{.spec.ports[?(@.port==443)].port}'); \
	if [ -z "$$HTTPS_PORT" ]; then echo "❌ The live QA Gateway Service does not expose HTTPS port 443 yet. Sync its ApplicationSet from the tracked Git revision."; exit 1; fi; \
	echo "🔒 Port-forwarding to service/$$SVC_NAME on https://localhost:8444..."; \
	kubectl port-forward -n envoy-gateway-system service/$$SVC_NAME 8444:443

# Port-forward to the production Envoy Gateway HTTPS listener
port-forward-gateway-prod-https:
	@SVC_NAME=$$(kubectl get svc -n envoy-gateway-system --selector=gateway.envoyproxy.io/owning-gateway-namespace=envoy-gateway-system,gateway.envoyproxy.io/owning-gateway-name=envoy-data-plane-prod -o jsonpath='{.items[0].metadata.name}'); \
	if [ -z "$$SVC_NAME" ]; then echo "❌ Could not find the production Gateway proxy service."; exit 1; fi; \
	HTTPS_PORT=$$(kubectl get svc -n envoy-gateway-system "$$SVC_NAME" -o jsonpath='{.spec.ports[?(@.port==443)].port}'); \
	if [ -z "$$HTTPS_PORT" ]; then echo "❌ The live production Gateway Service does not expose HTTPS port 443 yet. Sync its ApplicationSet from the tracked Git revision."; exit 1; fi; \
	echo "🔒 Port-forwarding to service/$$SVC_NAME on https://localhost:8445..."; \
	kubectl port-forward -n envoy-gateway-system service/$$SVC_NAME 8445:443

# Get the Argo CD password
argocd-password:
	kubectl -n argocd get secret argocd-initial-admin-secret \
		-o jsonpath="{.data.password}" | base64 --decode

# Port-forward to the Envoy Stats
port-forward-envoy-stats:
	@POD=$$(kubectl get pods -n $(ENVOY_NAMESPACE) \
	-l gateway.envoyproxy.io/owning-gateway-name=envoy-data-plane-dev \
		-o jsonpath='{.items[0].metadata.name}'); \
	echo "Envoy pod: $$POD"; \
	kubectl port-forward -n $(ENVOY_NAMESPACE) pod/$$POD $(ENVOY_ADMIN_PORT):19000

port-forward-grafana:
	@echo "🚀 Grafana open at http://localhost:3000"
	kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80

# Port-forward to the Prometheus UI for running PromQL queries
port-forward-prometheus:
	@echo "🚀 Prometheus open at http://localhost:9090"
	kubectl port-forward -n $(PROMETHEUS_NAMESPACE) svc/$(PROMETHEUS_SERVICE) 9090:9090
