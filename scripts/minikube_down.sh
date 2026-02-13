#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-newsletter}"
REMOVE_IMAGES=false
STOP_CLUSTER=false

usage() {
  cat <<USAGE
Usage: $0 [--remove-images] [--stop-cluster]

Options:
  --remove-images   Remove local Minikube images used by this project
  --stop-cluster    Stop Minikube after deleting namespace
  -h, --help        Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove-images)
      REMOVE_IMAGES=true
      shift
      ;;
    --stop-cluster)
      STOP_CLUSTER=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required"
  exit 1
fi

kubectl delete namespace "$NAMESPACE" --ignore-not-found=true

if [[ "$REMOVE_IMAGES" == "true" ]]; then
  if ! command -v minikube >/dev/null 2>&1; then
    echo "minikube is required for --remove-images"
    exit 1
  fi
  minikube image rm newsletter:local >/dev/null 2>&1 || true
  minikube image rm newsletter-migrate:local >/dev/null 2>&1 || true
fi

if [[ "$STOP_CLUSTER" == "true" ]]; then
  if ! command -v minikube >/dev/null 2>&1; then
    echo "minikube is required for --stop-cluster"
    exit 1
  fi
  minikube stop
fi

echo "Minikube resources cleaned for namespace '$NAMESPACE'."
