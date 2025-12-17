# Anexo — BFF: pasar de stubs a producción (mapeo técnico)

> Este anexo traduce “PENDING/stub” a tareas concretas en NestJS.
> Úsalo como checklist de implementación + pruebas.

---

## 1) Principio: stubs sólo en `NODE_ENV=local`

En `staging|production`:
- no se permite almacenamiento en memoria para entidades críticas (casos, contratos, webhooks)
- no se permite “OCR stub” ni “presign stub”
- no se permite “enabled=true” sin secret (fail-fast)

---

## 2) Cases module (Expediente / Evidencia)

### Estado típico blueprint
- `CasesService` guarda en memoria
- `presign` devuelve stub
- `ocr` devuelve stub

### Implementación mínima a producción
- Persistencia en NEON:
  - tabla `cases` + `case_files` (o equivalente)
  - `case_id` UUID, `status`, `customer_id`, `created_at`
- Storage de archivos:
  - S3 presigned URLs para upload/download (TTL corto)
  - guardar `s3_key`, `content_type`, `size`, `sha256`
- OCR:
  - usar OpenAI Vision (o proveedor equivalente) para extraer campos
  - persistir resultado OCR (`ocr_text`, `confidence`, `extracted_fields JSONB`)
- Seguridad:
  - firmar uploads (no permitir overwrite arbitrario)
  - size limits

### Pruebas
- upload 1 archivo → queda en S3 + row en DB
- ejecutar OCR → row actualizada + respuesta API

---

## 3) WebhookRetryService (resiliencia real)

### Estado típico blueprint
- cola en memoria
- DLQ sin persistencia

### Implementación mínima a producción
- Persistir cola y DLQ en NEON:
  - `webhook_jobs` (pending/processing/success/failed)
  - `webhook_attempts` (histórico)
- Idempotencia:
  - llave única: `provider + event_id`
- Reintentos:
  - backoff exponencial + jitter
- Observabilidad:
  - endpoint admin: stats, DLQ list, replay

### Pruebas
- simular webhook duplicado → no duplica asiento
- simular fallo Odoo → reintenta y finalmente DLQ
- replay DLQ tras fix → éxito

---

## 4) Payments (Conekta)

### Implementación mínima a producción
- creación de orders/checkout con metadata:
  - `customer_id`, `contract_id`, `virtual_account_id`, `correlation_id`
- webhook handler:
  - valida firma
  - normaliza payload
  - encola job en `webhookRetryService`
- posting:
  - crear transacción staging + antifraude
  - crear `account.move` en Odoo
  - registrar `transactions` en NEON
  - marcar conciliación cuando haya extracto NEON

---

## 5) KYC (Metamap) + Contracts (Mifiel)

- exponer endpoints idempotentes:
  - crear verificación
  - consultar status
- webhook/callback:
  - persistir status final y razones
- firma:
  - crear documento
  - recibir signed callback
  - adjuntar PDF a Odoo/NEON

---

## 6) KIBAN/HASE + Voice

Opciones:
- **A) scoring externo (KIBAN)**
  - BFF actúa como proxy y persiste en `hase_scores`
- **B) scoring interno**
  - BFF llama scripts TS/Python (servicio separado ideal)
  - persiste `hase_scores` y expone al cockpit

Prueba mínima:
- `POST /api/voice/score` devuelve GO/REVIEW/NO-GO
- `POST /api/hase/score` devuelve score final + tier

---

## 7) Health checks por integración

Recomendación:
- `GET /health/integrations`
  - Odoo: auth + ping
  - NEON: SELECT 1
  - Conekta: API key validate (o request mínimo)
  - Mifiel/Metamap: request mínimo
  - OpenAI: request mínimo (sin costo alto)
