#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="envoy-gateway-system"
SECRET_NAME="dev-localhost-tls"
LOCAL_DIR=".local"
CERT_FILE="${LOCAL_DIR}/dev-localhost.crt"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TEMP_DIR}"' EXIT

command -v openssl >/dev/null || { echo "openssl is required" >&2; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is required" >&2; exit 1; }

mkdir -p "${LOCAL_DIR}"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "${TEMP_DIR}/tls.key" \
  -out "${CERT_FILE}" \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret tls "${SECRET_NAME}" \
  --namespace "${NAMESPACE}" \
  --cert="${CERT_FILE}" \
  --key="${TEMP_DIR}/tls.key" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Created ${SECRET_NAME} in ${NAMESPACE}."
echo "Trust the self-signed certificate with: curl --cacert ${CERT_FILE} https://localhost:8443/"
