#!/usr/bin/env bash
set -euo pipefail

TASK_DIR="/root/task"
LOCALSTACK_ENDPOINT="http://127.0.0.1:4566"

cd "${TASK_DIR}"

echo "[run.sh] Starting local infrastructure emulator (LocalStack)..."
docker compose up -d

echo "[run.sh] Waiting for LocalStack to become healthy..."
ATTEMPTS=0
MAX_ATTEMPTS=40
until curl -sf "${LOCALSTACK_ENDPOINT}/_localstack/health" >/dev/null 2>&1; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "${ATTEMPTS}" -ge "${MAX_ATTEMPTS}" ]; then
    echo "[run.sh] ERROR: LocalStack did not become ready in time." >&2
    docker compose logs --tail=50 localstack >&2 || true
    exit 1
  fi
  sleep 3
done
echo "[run.sh] LocalStack is healthy."

# Seed the 'existing' prod queues into the emulator so the candidate can
# reason about state/rename safety against pre-existing resources.
# This represents infrastructure that already exists in production.
echo "[run.sh] Seeding pre-existing checkout queues into the emulator..."
seed_queue() {
  local qname="$1"
  curl -s -X POST "${LOCALSTACK_ENDPOINT}/_aws/sqs/queues" >/dev/null 2>&1 || true
  curl -s "${LOCALSTACK_ENDPOINT}/?Action=CreateQueue&QueueName=${qname}" >/dev/null 2>&1 || true
}
for q in orders-created orders-created-dlq payments-captured payments-captured-dlq inventory-reserved inventory-reserved-dlq; do
  seed_queue "${q}"
done
echo "[run.sh] Seed step complete (best-effort)."

echo "[run.sh] Validating Terraform project layout..."
if [ ! -f "${TASK_DIR}/main.tf" ]; then
  echo "[run.sh] ERROR: main.tf not found in ${TASK_DIR}" >&2
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "[run.sh] WARNING: terraform CLI not found on PATH. Install it to run plan/validate." >&2
else
  echo "[run.sh] Running terraform init (backend disabled for local sandbox)..."
  terraform init -input=false -backend=false >/dev/null
  echo "[run.sh] terraform init complete. The project is ready for inspection."
  echo "[run.sh] NOTE: fmt/validate/plan are left for the candidate to run and reason about."
fi

echo "[run.sh] Setup finished. LocalStack is available at ${LOCALSTACK_ENDPOINT}."

