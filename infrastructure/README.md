# Kubernetes platform configuration

This directory contains Helm charts and values for platform components installed in the cluster, including Argo CD and Envoy Gateway. Argo CD Applications and ApplicationSets are maintained in `apps/`.

Google Cloud infrastructure, including the shared GKE cluster and its VPC, is provisioned separately with Terraform in [`../terraform/gke/`](../terraform/gke/README.md). Provision the cluster before installing Argo CD with `scripts/install-argocd.sh`.
