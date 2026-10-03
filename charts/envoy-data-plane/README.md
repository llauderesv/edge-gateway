# Envoy Gateway Data Plane Chart

This chart configures an environment's Envoy Gateway data plane. The `envoy-data-plane` ApplicationSet in `apps/platforms/` creates one Argo CD Application for each environment: `dev`, `qa`, and `prod`.

The ApplicationSet passes environment-specific Helm values inline. Gateway and EnvoyProxy names are derived from the environment suffix:

| Environment | Gateway | EnvoyProxy | Listener |
| --- | --- | --- | --- |
| `dev` | `envoy-data-plane-dev` | `eg-dev` | HTTP on port 80 |
| `qa` | `envoy-data-plane-qa` | `eg-qa` | HTTPS on port 443 for `qa.api.company.com` |
| `prod` | `envoy-data-plane-prod` | `eg-prod` | HTTPS on port 443 for `api.company.com` |

QA and production require their TLS Secrets (`qa-tls-cert` and `prod-api-cert`) in the `envoy-gateway-system` namespace.

## Resources

The chart renders:

- A `Gateway` for the selected environment, using the shared `GatewayClass` named `eg`.
- An `EnvoyProxy` configuration referenced by that Gateway.

The Envoy Gateway controller and CRDs are installed by the `envoy-gateway` Argo CD Application. The cluster-scoped `GatewayClass` is also managed there. This chart does not create either resource.

## Routing services through a Gateway

Service `HTTPRoute` resources are managed separately by the `edge-service` chart. Set each service's `gateway.name` to the Gateway for its environment and `gateway.namespace` to `envoy-gateway-system`. For example, a dev route should reference:

```yaml
gateway:
  name: envoy-data-plane-dev
  namespace: envoy-gateway-system
```

The Gateways allow routes from other namespaces so service routes can attach from their own namespaces.

## Adding an environment

Add an element to the list generator in `apps/platforms/envoy-data-plane.yaml` with its listener settings. The ApplicationSet derives the Argo CD Application, Gateway, and EnvoyProxy names from the `environment` value. Add or reference any required TLS Secret in `envoy-gateway-system`.
