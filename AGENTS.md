Edge Gateway

# Overview

Edge Gateway is an enterprise-grade global API gateway platform built on Kubernetes Gateway API and GitOps principles. It provides centralized traffic management, routing, security, and policy enforcement across multi-region environments. Powered by ArgoCD, Helm, and Gateway API resources, Edge Gateway enables teams to manage APIs consistently at scale with support for rate limiting, authentication, observability, and progressive delivery.

## Folder structure

```sh
├── AGENTS.md
├── Makefile
├── README.md
├── apps
│   ├── external-backend # Contains all the services who upstreamed by the Edge Gateway
│   │   └── payment-api.yaml
│   ├── external-backend.yaml # Root apps-of-apps pattern for all external-backend
│   ├── platforms # Contains all the infrastructure related in the Cluster components. 
│   │   ├── argocd.yaml
│   │   ├── envoy-gateway.yaml
│   │   └── gateway-dev.yaml
│   ├── project.yaml
│   └── root-app.yaml
├── charts
│   ├── edge-gateway # Shared Helm charts for setting up the Gateway resource different per env {dev,qa,prod}
│   │   ├── Chart.yaml
│   │   ├── templates
│   │   │   └── gateway.yaml
│   │   └── values.yaml
│   └── edge-service # Shared Helm charts of for setting up new upstream services
│       ├── Chart.yaml
│       ├── templates
│       │   ├── _helpers.yaml
│       │   ├── backend.yaml
│       │   ├── backendtrafficpolicy.yaml
│       │   ├── httproute.yaml
│       │   ├── securitypolicy.yaml
│       │   └── timeoutpolicy.yaml
│       └── values.yaml
├── infrastructure # Localize Helm Charts of all the Infrastructure Cluster components in the Edge Gateway
│   ├── README.md
│   ├── argocd
│   │   ├── Chart.lock
│   │   ├── Chart.yaml
│   │   ├── charts
│   │   │   └── argo-cd-8.3.6.tgz
│   │   └── values-dev.yaml
│   └── envoy-gateway
│       ├── Chart.yaml
│       ├── templates
│       │   ├── envoyproxy.yaml
│       │   └── gatewayclass.yaml
│       ├── values-dev.yaml
│       └── values.yaml
├── scripts # Shared script 
│   ├── install-argocd.sh
│   └── validate.sh # Use to validate onboarding upstream servies
└── services # Config overrides of the upstream services per environment
    └── payment-api
        ├── values-dev.yaml
        ├── values-qa.yaml
        └── values.yaml
```