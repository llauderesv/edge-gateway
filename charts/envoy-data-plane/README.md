# Envoy Gateway Data Plane Chart

This chart configures an environment's Envoy Gateway data plane. The `envoy-data-plane` ApplicationSet in `apps/platforms/` creates one Argo CD Application for each environment: `dev`, `qa`, and `prod`.

The ApplicationSet passes environment-specific Helm values inline. Gateway and EnvoyProxy names are derived from the environment suffix:

| Environment | Gateway | EnvoyProxy | Listener |
| --- | --- | --- | --- |
| `dev` | `envoy-data-plane-dev` | `eg-dev` | HTTP on port 80 and HTTPS on port 443 for `localhost` |
| `qa` | `envoy-data-plane-qa` | `eg-qa` | HTTPS on port 443 for `localhost` |
| `prod` | `envoy-data-plane-prod` | `eg-prod` | HTTPS on port 443 for `localhost` |

All three environments temporarily use the `dev-localhost-tls` Secret in the `envoy-gateway-system` namespace. Create or refresh it from the repository root with `bash scripts/create-dev-tls-secret.sh`. The generated certificate is self-signed and saved at `.local/dev-localhost.crt` for local client trust; the private key is temporary and is not stored in the repository.

For local HTTPS access, run the matching command: `make port-forward-gateway-https` (dev, port 8443), `make port-forward-gateway-qa-https` (QA, port 8444), or `make port-forward-gateway-prod-https` (production, port 8445). Connect to the corresponding `https://localhost:<port>` URL and trust `.local/dev-localhost.crt` in your client. The dev HTTP listener on port 80 remains available through `make port-forward-gateway`.

QA and production need their own TLS Secrets in the `envoy-gateway-system` namespace before HTTPS can be enabled for their hostnames.

## Resources

The chart renders:

- A `Gateway` for the selected environment, using the shared `GatewayClass` named `eg`.
- An `EnvoyProxy` configuration referenced by that Gateway.

The Envoy Gateway controller and CRDs are installed by the `envoy-gateway` Argo CD Application. The cluster-scoped `GatewayClass` is also managed there. This chart does not create either resource.

## Routing services through a Gateway

Service `HTTPRoute` resources are managed separately by the `upstream-service` chart. Set each service's `gateway.name` to the Gateway for its environment and `gateway.namespace` to `envoy-gateway-system`. For example, a dev route should reference:

```yaml
gateway:
  name: envoy-data-plane-dev
  namespace: envoy-gateway-system
```

The Gateways allow routes from other namespaces so service routes can attach from their own namespaces.

## Adding an environment

Add an element to the list generator in `apps/platforms/envoy-data-plane.yaml` with its listener settings. The ApplicationSet derives the Argo CD Application, Gateway, and EnvoyProxy names from the `environment` value. Add or reference any required TLS Secret in `envoy-gateway-system`.
