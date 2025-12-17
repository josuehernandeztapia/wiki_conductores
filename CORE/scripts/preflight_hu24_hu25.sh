#!/usr/bin/env bash
set -euo pipefail

# Preflight HU24/HU25 — validación rápida de staging antes de correr el piloto.
#
# Uso:
#   BFF_BASE_URL=https://staging-bff.tu-dominio.com \
#   INTERNAL_API_KEY=... \
#   bash CORE/scripts/preflight_hu24_hu25.sh | tee preflight_output.txt
#
# Opcionales:
#   HEALTH_PATH=/health
#   INTEGRATIONS_PATH=/health/integrations
#   CURL_TIMEOUT=12

BFF_BASE_URL="${BFF_BASE_URL:-}"
INTERNAL_API_KEY="${INTERNAL_API_KEY:-}"
HEALTH_PATH="${HEALTH_PATH:-/health}"
INTEGRATIONS_PATH="${INTEGRATIONS_PATH:-/health/integrations}"
CURL_TIMEOUT="${CURL_TIMEOUT:-12}"

if [[ -z "$BFF_BASE_URL" ]]; then
  echo "ERROR: define BFF_BASE_URL (ej. https://staging-bff.tu-dominio.com)" >&2
  exit 1
fi

hdr=()
if [[ -n "$INTERNAL_API_KEY" ]]; then
  hdr+=("-H" "x-internal-api-key: $INTERNAL_API_KEY")
fi

echo "== Preflight HU24/HU25 =="
echo "BFF_BASE_URL: $BFF_BASE_URL"
echo "HEALTH_PATH: $HEALTH_PATH"
echo "INTEGRATIONS_PATH: $INTEGRATIONS_PATH"
echo

echo "== 1) Health básico =="
set +e
health_resp="$(curl -sS --max-time "$CURL_TIMEOUT" "$BFF_BASE_URL$HEALTH_PATH")"
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  echo "ERROR: no responde $BFF_BASE_URL$HEALTH_PATH"
  exit 1
fi
echo "$health_resp" | head -c 500
echo; echo

echo "== 2) Health de integraciones (protegido) =="
set +e
int_resp="$(curl -sS --max-time "$CURL_TIMEOUT" "${hdr[@]}" "$BFF_BASE_URL$INTEGRATIONS_PATH")"
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  echo "ERROR: no responde $BFF_BASE_URL$INTEGRATIONS_PATH (o falta auth)" >&2
  exit 1
fi
echo "$int_resp" | head -c 2000
echo; echo

echo "== 3) Gate rápido (si hay jq) =="
if command -v jq >/dev/null 2>&1; then
  ok="$(echo "$int_resp" | jq -r '.ok // empty')"
  echo "integrations.ok: ${ok:-<no field>}"
  if [[ "$ok" != "true" ]]; then
    echo "ERROR: integraciones NO listas para piloto (ok != true)" >&2
    exit 2
  fi
else
  echo "jq no instalado; validación manual: busca \"ok\": true en la salida."
  echo "$int_resp" | grep -q '"ok"[[:space:]]*:[[:space:]]*true' || {
    echo "ERROR: integraciones NO listas para piloto (no se encontró ok=true)" >&2
    exit 2
  }
fi
echo

echo "== OK: Preflight pasó. Puedes ejecutar HU25 (piloto) =="
