# Edge Service Chart

This Helm chart onboards an upstream service to the Edge Gateway. It creates the Gateway API and Envoy Gateway resources needed to expose either a Kubernetes Service or an external backend through a shared `Gateway`.

Environment-specific values belong in `services/<service-name>/values-<environment>.yaml`. An Argo CD `ApplicationSet` in `apps/external-backend/` discovers service directories and creates an Application for each service.

## Resources created

| Template | Resource | Created when | Purpose |
| --- | --- | --- | --- |
| `httproute.yaml` | `HTTPRoute` | Always | Matches incoming requests and sends them to the upstream backend. |
| `backend.yaml` | `Backend` | `backend.type: external` | Represents an external DNS backend. |
| `backendtrafficpolicy.yaml` | `BackendTrafficPolicy` | `rateLimit.enabled: true` | Applies global request rate limiting to the route. |
| `timeoutpolicy.yaml` | `BackendTrafficPolicy` | `timeouts.enabled: true` | Sets the upstream request timeout. |
| `securitypolicy.yaml` | `SecurityPolicy` | `security.enabled: true` | Creates a policy attached to the route. |

Generated resource names use the service name. For example, `payment-api` creates the HTTPRoute `payment-api-route` and the external Backend `payment-api-backend`.

## Required values

```yaml
service:
  name: catalog-api
  namespace: catalog

gateway:
  name: envoy-data-plane-dev
  namespace: envoy-gateway-system

route:
  hostnames:
    - api.example.com
  path: /catalog
  pathType: PathPrefix
```

By default, the route forwards the request with its original host and path. Add a rewrite only when the upstream requires one. For example, this strips `/catalog` from `/catalog/items` and sends the request upstream as `/items`:

```yaml
route:
  rewrite:
    path:
      type: ReplacePrefixMatch
      replacePrefixMatch: /
```

To change the upstream host, configure `route.rewrite.hostname`. Host and path rewrites can be used independently or together:

```yaml
route:
  rewrite:
    hostname: upstream.example.com
```

Choose one backend type.

### Kubernetes Service backend

Use this for an upstream that runs in the cluster and is exposed by a Kubernetes Service.

```yaml
backend:
  type: kubernetes
  service:
    name: catalog-api
    port: 8080
```

### External backend

Use this for an upstream reachable by DNS from the Envoy data plane.

```yaml
backend:
  type: external
  external:
    host: api.internal.example.com
    port: 443
```

## Optional policies

```yaml
rateLimit:
  enabled: true
  requests: 100
  unit: Minute

timeouts:
  enabled: false
  request: 15s

security:
  enabled: false
```

## Onboarding workflow

1. Create `services/<service-name>/values.yaml` with shared service, route, and backend configuration.
2. Create environment overrides such as `services/<service-name>/values-dev.yaml`.
3. Add a service directory under `services/`. The ApplicationSet discovers it and creates an Argo CD Application using `charts/upstream-service` and the shared and environment values files.
4. Sync the application and check that the HTTPRoute reports `Accepted` and `ResolvedRefs` conditions as `True`.
5. Send a request through the Gateway and inspect Envoy access logs and Prometheus metrics.

## Monitoring

The shared Envoy data plane is monitored by the ServiceMonitor in `infrastructure/monitoring/resources/`. Gateway request metrics are labeled by the generated upstream cluster, so a separate ServiceMonitor is not required for every onboarded route.

If an upstream application exposes its own `/metrics` endpoint, create that application's ServiceMonitor alongside the application's deployment chart or manifests.

## Current chart constraints

- HTTPRoute rewrites are optional and configured per service under `route.rewrite`. Without a rewrite, the original request host and path are preserved.
- Do not enable both `rateLimit.enabled` and `timeouts.enabled` at the same time. Both templates currently create a `BackendTrafficPolicy` with the same name.
- Enabling `security.enabled` creates and attaches a `SecurityPolicy`, but the chart does not yet configure authentication or authorization settings in that policy.
