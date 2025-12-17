# ANEXO — Implementación HU24 (código) para pasar de *stubs* a producción

> Objetivo: aterrizar HU24 (integraciones reales) en cambios de código concretos para que HU25 (piloto) sea ejecutable con evidencia.

> Este anexo **complementa** (no reemplaza) los runbooks/checklists:
> - `CORE/CORE_FASE10_PILOTO_OPERATIVO.md`
> - `CORE/CHECKLIST_HU24_HU25_OPERATIVO.md`
> - `CORE/CORE_FASE9_CHECKLIST_CIERRE_PILOTO.md`
> - `CORE/ANEXO_SECRETS_ENVIRONMENTS.md`
> - `CORE/ANEXO_BFF_STUBS_TO_PROD.md`

---

## 0) Principios operativos (para no “romper” el piloto)

1) **Fail‑fast**: en `staging/production` no existe modo stub.
2) **Idempotencia**: eventos externos (webhooks) nunca deben duplicar asientos/transacciones.
3) **Persistencia**: colas, DLQ y evidencias viven en NEON (no memoria).
4) **Trazabilidad**: `correlation_id` viaja PWA → BFF → externos → NEON.
5) **PII**: evidencias se guardan redactadas (IDs sí, datos personales no).

---

## 1) Cambio P0 — Validación estricta de configuración (fail‑fast)

### Qué lograr
- Si `*_ENABLED=true` y falta un secret, el BFF **no arranca**.
- Si `NODE_ENV=production|staging`, **ningún** servicio puede usar mocks.

### Dónde tocar (BFF)
- `bff/src/config/production-endpoints.config.ts` (ya tiene flags/validate).
- `bff/src/main.ts` (o bootstrap).

### Patrón recomendado (simple y efectivo)
**A. Variables por integración (mínimo):**
- NEON DB: `NEON_DATABASE_URL`
- Odoo: `ODOO_URL`, `ODOO_DB`, `ODOO_USERNAME`, `ODOO_PASSWORD` *(o API key si aplica)*
- Conekta: `CONEKTA_PRIVATE_KEY`, `CONEKTA_WEBHOOK_SECRET`
- Mifiel: `MIFIEL_APP_ID`, `MIFIEL_PRIVATE_KEY` *(y/o certificado)*
- Metamap: `METAMAP_API_KEY` *(y secret webhook si aplica)*
- OpenAI/OCR: `OPENAI_API_KEY`
- S3: `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `S3_BUCKET`

**B. Helper sugerido:**
- `assertEnv(required: string[]): void` que lanza con lista de faltantes.

**C. Gate recomendado:**
- En `bootstrap()`:
  - exigir siempre `NEON_DATABASE_URL` en staging/prod
  - por cada integración habilitada, exigir sus secrets
  - **prohibir** arrancar si `enabled=true` y `mock=true`

**Evidencia HU24**
- Log de arranque OK.
- Prueba negativa: arrancar con 1 secret faltante → crash con mensaje claro.

---

## 2) Cambio P0 — `GET /health/integrations` (gates para HU25)

### Qué lograr
Un endpoint único que diga, por integración:
- enabled/disabled
- ok/fail
- latencia
- error resumido

### Respuesta recomendada
```json
{
  "timestamp": "2025-12-17T00:00:00.000Z",
  "env": "staging",
  "ok": false,
  "checks": [
    {"name":"neon_db","enabled":true,"ok":true,"latency_ms":12},
    {"name":"odoo","enabled":true,"ok":false,"latency_ms":0,"error":"auth failed"},
    {"name":"conekta","enabled":true,"ok":true,"latency_ms":230}
  ]
}
```

### Checks mínimos por integración
- NEON: `SELECT 1`
- Odoo: authenticate + `res.partner.search_count([])` (no destructivo)
- Conekta: endpoint no destructivo (ej. “list/retrieve”)
- Metamap/Mifiel: “retrieve by id” de prueba o “ping”
- OpenAI: llamada trivial (si permitido)
- S3: `HeadBucket` o presign de prueba

**Importante**: este endpoint debe ir protegido (API key interna / allowlist / auth).

---

## 3) Cambio P0 — `webhookRetryService` persistente (cola + DLQ en NEON)

### Qué lograr
- Cola persistente en NEON (jobs + attempts).
- Worker con `SELECT ... FOR UPDATE SKIP LOCKED`.
- Idempotencia por `(provider, event_id)`.

### Entregables (en este pack)
- SQL DDL: `CORE/sql/001_webhook_retry_tables.sql`
- Script preflight (incluye validación de health): `CORE/scripts/preflight_hu24_hu25.sh`

### Reglas mínimas
- `max_attempts` por tipo (ej. Conekta 10, Odoo 5).
- Backoff exponencial con jitter.
- En cada intento: log con `correlation_id` + `provider_event_id`.

---

## 4) Cambio P0 — Conekta `order.paid` → asiento Odoo → `transactions` NEON

### Qué lograr
Tras un pago real controlado:
1) webhook entra (firma verificada),
2) se encola job `CONEKTA_ORDER_PAID`,
3) se crea asiento en Odoo (101/405),
4) se inserta transaction en NEON,
5) conciliación usa extracto NEON.

### Idempotencia recomendada
- Unique index `(provider, provider_event_id)` en cola.
- Unique index `(provider, external_id)` en `transactions`.

### Evidencia HU25
- payload webhook redactado + logs con correlation_id
- `account.move` id en Odoo
- row en `transactions` (NEON) con `external_id=order_id`

---

## 5) Cambio P1 — Cases/Expediente: S3 presign + OCR + NEON

### Qué lograr
- presign real (PUT) + registro metadata en NEON
- OCR asíncrono por job (no bloqueante)
- persistencia de resultado (JSON) con versionado de modelo

### Entidades sugeridas (NEON)
- `cases`
- `case_evidence` (case_id, s3_key, sha256, mime, size, created_at)
- `case_ocr` (evidence_id, model, extracted_json, confidence, created_at)

---

## 6) Cambio P1 — PWA: bloquear acciones si integraciones no están listas

### Qué lograr
- Cockpit/originación muestra “Integraciones ✅/❌”.
- Si una integración crítica está ❌, se deshabilita el CTA y se explica qué falta.

### Cómo
- Angular service que llama `GET /health/integrations`
- Componente `IntegrationsStatus` (o equivalente)

---

## 7) Preflight automatizado (antes de HU25)

Ver `CORE/scripts/preflight_hu24_hu25.sh`.

Guarda el output en:
- `EVIDENCIAS/HU25/00_preflight/preflight_output.txt`

---

## 8) Conexión a evidencias HU24/HU25

Para cada paso del piloto, guardar:
- request/response redactado
- IDs cruzados (Odoo/Conekta/Metamap/Mifiel/NEON)
- logs filtrados por `correlation_id`

Ver estructura sugerida en `EVIDENCIAS_TEMPLATE/`.
