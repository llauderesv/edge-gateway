# Kubernetes platform configuration

This directory contains Helm charts and values for platform components installed in the cluster, including Argo CD and Envoy Gateway. Argo CD Applications and ApplicationSets are maintained in `apps/`.

Google Cloud infrastructure, including the shared GKE cluster and its VPC, is provisioned separately with Terraform in [`../terraform/gke/`](../terraform/gke/README.md). Provision the cluster before installing Argo CD with `scripts/install-argocd.sh`.

## Exposing cluster add-ons

Gateway API routes for cluster add-ons live in `resources/addon-routes/` and are deployed by the `addon-routes` Argo CD Application in `apps/platforms/`. Keep each add-on's `HTTPRoute` in its own file and in the same namespace as its Service. Argo CD has a dedicated Gateway and Envoy data plane, declared in `apps/platforms/argocd-gateway.yaml`; its route is in `argocd.yaml`. Prometheus and Grafana routes can be added alongside it later and attached to their chosen Gateway.

The Argo CD route attaches to `argocd-gateway-dev` in `envoy-gateway-system` on HTTPS hostname `localhost`, using the existing `dev-localhost-tls` Secret. The Argo CD server runs in insecure HTTP mode behind the Gateway, which terminates TLS. For a real DNS name, update both the Gateway listener hostname and route hostname, then configure a matching certificate.

For local access through this Gateway, run `make port-forward-argocd-gateway`, then open `https://localhost:9443` and trust the local development certificate.
