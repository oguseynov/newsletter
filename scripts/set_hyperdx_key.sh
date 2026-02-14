#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-newsletter}"
SECRET_NAME="newsletter-secrets"
SECRET_KEY="otel-api-key"
DEPLOYMENT_NAME="newsletter"
COLLECTOR_DAEMONSET_NAME="otel-logs-collector"
RESTART_DEPLOYMENT=true

if [[ "${1:-}" == "--no-restart" ]]; then
  RESTART_DEPLOYMENT=false
elif [[ -n "${1:-}" ]]; then
  echo "Usage: HYPERDX_INGESTION_KEY=<key> $0 [--no-restart]"
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required"
  exit 1
fi

if [[ -z "${HYPERDX_INGESTION_KEY:-}" ]]; then
  echo "HYPERDX_INGESTION_KEY is required"
  echo "Example: HYPERDX_INGESTION_KEY=xxxx $0"
  exit 1
fi

kubectl -n "$NAMESPACE" create secret generic "$SECRET_NAME" \
  --from-literal="$SECRET_KEY=$HYPERDX_INGESTION_KEY" \
  --dry-run=client -o yaml | kubectl apply -f -

if [[ "$RESTART_DEPLOYMENT" == "true" ]]; then
  kubectl -n "$NAMESPACE" rollout restart deployment/"$DEPLOYMENT_NAME"
  kubectl -n "$NAMESPACE" rollout status deployment/"$DEPLOYMENT_NAME" --timeout=180s
  kubectl -n "$NAMESPACE" rollout restart daemonset/"$COLLECTOR_DAEMONSET_NAME"
  kubectl -n "$NAMESPACE" rollout status daemonset/"$COLLECTOR_DAEMONSET_NAME" --timeout=180s
fi

echo "Secret '$SECRET_NAME' updated in namespace '$NAMESPACE'."
