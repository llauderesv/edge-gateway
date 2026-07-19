#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT="${1:?environment is required (dev|qa|prod)}"

# CLUSTER_NAME="edge-gateway-${ENVIRONMENT}"
CLUSTER_NAME="edge-gateway"

VALUES_FILE="./infrastructure/argocd/values-${ENVIRONMENT}.yaml"

ARGO_NAMESPACE="argocd"

HELM_RELEASE="argocd"

case "${ENVIRONMENT}" in
  dev|qa|prod)
    ;;
  *)
    echo "Invalid environment: ${ENVIRONMENT}"
    echo "Allowed values: dev, qa, prod"
    exit 1
    ;;
esac

if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "Values file not found:"
  echo "${VALUES_FILE}"
  exit 1
fi

echo "========================================"
echo "Installing Argo CD"
echo "Environment : ${ENVIRONMENT}"
echo "Cluster     : ${CLUSTER_NAME}"
echo "Namespace   : ${ARGO_NAMESPACE}"
echo "========================================"

kubectl config use-context "${CLUSTER_NAME}"

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update

kubectl create namespace "${ARGO_NAMESPACE}" \
  --dry-run=client \
  -o yaml | kubectl apply -f -

helm upgrade \
  --install \
  "${HELM_RELEASE}" \
  argo/argo-cd \
  --namespace "${ARGO_NAMESPACE}" \
  --create-namespace \
  --values "${VALUES_FILE}" \
  --wait \
  --timeout 10m

echo
echo "Argo CD successfully installed."

kubectl get pods -n "${ARGO_NAMESPACE}"