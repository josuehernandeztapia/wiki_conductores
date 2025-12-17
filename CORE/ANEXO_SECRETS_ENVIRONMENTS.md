# Anexo — Secrets y Ambientes (PWA/BFF/Odoo/NEON/IA)

> Objetivo: evitar “modo stub” y habilitar despliegue repetible (staging → producción).

---

## 1) Ambientes recomendados

- **local**: dev con stubs/mocks permitidos.
- **staging**: *igual que prod* pero con cuentas sandbox (Conekta/Mifiel/Metamap si existen).
- **production**: real.

Regla: **lo que no pasa en staging no se habilita en production**.

---

## 2) Política de secretos

- Nunca commitear `.env`, llaves privadas, certificados, tokens.
- Usar:
  - GitHub Actions Secrets (si el deployment es por CI)
  - Secret Manager (AWS Secrets Manager / GCP Secret Manager / Vault)
- Rotación:
  - Conekta / OpenAI / Metamap / Mifiel: cada 90 días o al detectar incidente.
- Least privilege:
  - S3: permisos por bucket/prefix, sin `s3:*`.
  - DB: usuario por servicio (BFF, jobs, BI) con permisos mínimos.

---

## 3) Variables mínimas (plantilla)

> Nombres sugeridos. Ajustar a lo que ya usa el repo (`bff/README.md`, `production-endpoints.config.ts`, etc.).

### 3.1 Runtime
- `NODE_ENV=local|staging|production`
- `PORT=3000`
- `LOG_LEVEL=debug|info|warn|error`
- `CORS_ORIGINS=https://pwa.example.com,https://staging-pwa.example.com`

### 3.2 NEON Database (Postgres SSOT)
- `NEON_DATABASE_URL=postgres://user:pass@host:5432/db`
- `NEON_DB_SSLMODE=require` (si aplica)
- `NEON_API_KEY=...` (si hay API REST con `X-Neon-Key`)
- `NEON_API_BASE_URL=https://...` (si hay FastAPI/REST externo)

### 3.3 Odoo (ERP / Ledger)
- `ODOO_BASE_URL=https://odoo.example.com`
- `ODOO_DB=odoo_db_name`
- `ODOO_USERNAME=...`
- `ODOO_PASSWORD=...`
- (Opcional) `ODOO_API_KEY=...` (si se usa un proxy/adapter)

### 3.4 Conekta
- `CONEKTA_PUBLIC_KEY=key_...`
- `CONEKTA_PRIVATE_KEY=key_...`
- `CONEKTA_WEBHOOK_SECRET=whsec_...`
- `CONEKTA_WEBHOOK_URL=https://bff.example.com/api/bff/webhooks/conekta`

### 3.5 Mifiel
- `MIFIEL_APP_ID=...`
- `MIFIEL_APP_SECRET=...`
- `MIFIEL_WEBHOOK_SECRET=...` (si aplica)
- `MIFIEL_WEBHOOK_URL=https://bff.example.com/api/bff/webhooks/mifiel`

### 3.6 Metamap
- `METAMAP_CLIENT_ID=...`
- `METAMAP_CLIENT_SECRET=...`
- `METAMAP_WEBHOOK_SECRET=...` (si aplica)

### 3.7 KIBAN/HASE + Voice Pattern
- `KIBAN_BASE_URL=https://...`
- `KIBAN_API_KEY=...`
- `VOICE_SCORING_PROVIDER=internal|kiban|hybrid`
- `VOICE_MIN_SCORE_GO=...` (si aplica)

### 3.8 OpenAI
- `OPENAI_API_KEY=sk-...`
- `OPENAI_MODEL_CHAT=gpt-4o-mini` (ejemplo)
- `OPENAI_MODEL_VISION=gpt-4o-mini` (ejemplo)
- `OPENAI_MODEL_EMBEDDINGS=text-embedding-3-small` (ejemplo)

### 3.9 AWS S3 (evidencias / expedientes / anexos)
- `AWS_ACCESS_KEY_ID=...`
- `AWS_SECRET_ACCESS_KEY=...`
- `AWS_REGION=us-east-1`
- `S3_BUCKET=conductores-prod`
- `S3_PREFIX=expedientes/`
- (Opcional) `S3_ENDPOINT=...` (MinIO/R2)

### 3.10 Notificaciones
- `TWILIO_ACCOUNT_SID=...`
- `TWILIO_AUTH_TOKEN=...`
- `TWILIO_FROM=whatsapp:+...` / `TWILIO_SMS_FROM=+...`
- `SENDGRID_API_KEY=...`
- `NOTIFICATIONS_FROM_EMAIL=...`

### 3.11 Flowise/Pinecone (RAG)
- `FLOWISE_BASE_URL=https://...`
- `FLOWISE_API_KEY=...`
- `PINECONE_API_KEY=...`
- `PINECONE_INDEX=higer-ssot`
- `PINECONE_ENVIRONMENT=...`

---

## 4) Pruebas de configuración (smoke)

Recomendación: exponer un endpoint interno protegido (solo admin) para validar conectividad:

- `GET /health` → status general
- `GET /health/integrations` → status por integración (odoo, conekta, metamap, mifiel, neon, kiban, openai)

**Importante:** nunca devolver secrets en claro; solo `enabled`, latencia, último error.

---

## 5) Convención de “enabled flags”

Para evitar stubs en producción, usar flags explícitos:

- `ODOO_ENABLED=true|false`
- `CONEKTA_ENABLED=true|false`
- `MIFIEL_ENABLED=true|false`
- `METAMAP_ENABLED=true|false`
- `NEON_BANK_ENABLED=true|false`
- `RAG_ENABLED=true|false`

En `production`:
- Si un flag es `true` y falta el secret → el servicio no arranca.
- Si un flag es `false` → el endpoint debe responder con error claro “Feature disabled” (y no stub).

