#!/usr/bin/env bash

set -euo pipefail

SERVICE="${1:?service is required}"
ENVIRONMENT="${2:?environment is required}"

CHART_PATH="./charts/edge-service"
SERVICE_PATH="./services/${SERVICE}"

COMMON_VALUES="${SERVICE_PATH}/values.yaml"
ENV_VALUES="${SERVICE_PATH}/values-${ENVIRONMENT}.yaml"

echo "========================================"
echo "Validating Edge Gateway configuration"
echo "Service: ${SERVICE}"
echo "Environment: ${ENVIRONMENT}"
echo "========================================"

if [[ ! -d "${SERVICE_PATH}" ]]; then
  echo "❌ Service '${SERVICE}' does not exist"
  exit 1
fi

if [[ ! -f "${ENV_VALUES}" ]]; then
  echo "❌ Missing values file:"
  echo "   ${ENV_VALUES}"
  exit 1
fi

ARGS=()

if [[ -f "${COMMON_VALUES}" ]]; then
  ARGS+=(
    -f "${COMMON_VALUES}"
  )
fi

ARGS+=(
  -f "${ENV_VALUES}"
)

echo
echo "Running helm lint..."

helm lint "${CHART_PATH}" "${ARGS[@]}"

echo
echo "Rendering templates..."

OUTPUT_FILE="/tmp/${SERVICE}-${ENVIRONMENT}.yaml"

helm template \
  "${SERVICE}" \
  "${CHART_PATH}" \
  "${ARGS[@]}" \
  > "${OUTPUT_FILE}"

echo "========================================"
echo "Rendered manifests"
echo "========================================"

cat "${OUTPUT_FILE}"

echo
echo "========================================"
echo "Validation successful"
echo "Manifest saved to:"
echo "${OUTPUT_FILE}"
echo "========================================"