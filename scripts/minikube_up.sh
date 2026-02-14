#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="newsletter"
MINIKUBE_CPUS="${MINIKUBE_CPUS:-5}"
MINIKUBE_MEMORY_MB="${MINIKUBE_MEMORY_MB:-10240}"
MINIKUBE_CNI="${MINIKUBE_CNI:-calico}"

if ! command -v minikube >/dev/null 2>&1; then
  echo "minikube is required"
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required"
  exit 1
fi

if ! minikube status >/dev/null 2>&1; then
  minikube start --cpus="$MINIKUBE_CPUS" --memory="$MINIKUBE_MEMORY_MB" --cni="$MINIKUBE_CNI"
fi

minikube image build -t newsletter:local -f Dockerfile .
minikube image build -t newsletter-migrate:local -f Dockerfile.migrate .

kubectl apply -k k8s/minikube
kubectl -n "$NAMESPACE" rollout status statefulset/postgres --timeout=300s
kubectl -n "$NAMESPACE" rollout status daemonset/otel-logs-collector --timeout=300s
kubectl -n "$NAMESPACE" wait --for=condition=ready pod -l app=postgres --timeout=180s

kubectl -n "$NAMESPACE" delete job migrate --ignore-not-found=true
kubectl apply -f k8s/minikube/migrate-job.yaml
if ! kubectl -n "$NAMESPACE" wait --for=condition=complete job/migrate --timeout=300s; then
  echo "migrate job did not complete in time. Showing diagnostics..."
  kubectl -n "$NAMESPACE" describe job migrate || true
  kubectl -n "$NAMESPACE" logs job/migrate --all-containers=true --tail=200 || true
  exit 1
fi

if [[ -n "${HYPERDX_INGESTION_KEY:-}" ]]; then
  ./scripts/set_hyperdx_key.sh --no-restart
fi

kubectl -n "$NAMESPACE" rollout status deployment/newsletter --timeout=300s

cat <<MSG

Minikube setup is ready.

Access HyperDX locally:
  kubectl -n $NAMESPACE port-forward svc/hyperdx 8080:8080 4317:4317 4318:4318

Access newsletter locally:
  kubectl -n $NAMESPACE port-forward svc/newsletter 8000:8000

Set/update ingestion key (optional, enables OTEL export):
  HYPERDX_INGESTION_KEY=<your-key> ./scripts/set_hyperdx_key.sh

MSG
