# CORE FASE 10 — Piloto Operativo (Runbook + Evidencias)

**Fecha de corte:** 2025-12-17  
**Propósito:** convertir el *blueprint* documentado en un **MVP operativo listo para piloto**, con evidencias auditables de punta a punta (HU25).

> Este documento está diseñado para ejecutarse como *guión operativo* (Runbook) y como *checklist de evidencias*.

---

## 1) Definición de “Listo para piloto”

Se considera **listo para piloto** cuando se cumplen **todas** estas condiciones:

### 1.1 Gate técnico (PWA + BFF)
- [ ] PWA apunta a BFF **productivo/staging** (no mocks) y puede completar el flujo de originación mínimo.
- [ ] BFF levanta con `NODE_ENV=staging|production` y **valida config** (no arranca si faltan secrets críticos).
- [ ] Swagger/Docs del BFF (o colección Postman) permiten ejecutar los *smoke tests*.
- [ ] Webhooks críticos están configurados y firmados (Conekta, Odoo/GNV si aplica) con idempotencia.

### 1.2 Gate de integraciones (HU24)
- [ ] Odoo (CRM + Accounting + módulo corebanking) operativo y accesible desde BFF.
- [ ] Metamap KYC operativo (sandbox o prod, pero real).
- [ ] Mifiel firma electrónica operativa (sandbox o prod).
- [ ] Conekta pagos operativos con webhooks en vivo.
- [ ] KIBAN/HASE y/o servicio interno de scoring (HASE + Voice) responde y persiste resultados.
- [ ] NEON Database (Postgres) accesible desde BFF y jobs (migraciones/particiones/backups).
- [ ] NEON Bank API (si se usa en piloto) habilitada al menos para **consultar** estados/extractos y ejecutar el paso operativo definido (SPEI/transferencias según FASE9).

### 1.3 Gate operativo (FASE9)
- [ ] Conciliación automática (aunque sea cada X horas) para Conekta → Odoo → NEON.
- [ ] Notificaciones mínimas (WhatsApp/SMS/email) para: pago recibido, firma pendiente, KYC pendiente.
- [ ] Backups automáticos (NEON) + evidencia de restore (al menos en staging).
- [ ] Runbooks listos para incidentes (ver `CORE/ANEXO_RUNBOOK_INCIDENTES.md`).
- [ ] PLD / antifraude mínimo: reglas y bitácora (aunque sea “v1”) para piloto.

---

## 2) “Guión” del piloto (HU25) — End-to-End

Este guión es el flujo **mínimo** para demostrar HU25 con evidencias y trazabilidad.

### 2.1 Preparación (Pre-flight)
1. **Ambientes y dominios**
   - [ ] PWA (staging/prod) con HTTPS.
   - [ ] BFF (staging/prod) con HTTPS.
   - [ ] Allowed origins / CORS correctos.
2. **Secrets**
   - [ ] Variables críticas cargadas en el entorno (ver `CORE/ANEXO_SECRETS_ENVIRONMENTS.md`).
3. **Integraciones**
   - [ ] Webhook endpoints publicados y validados (Conekta / Mifiel / etc.).
   - [ ] “Ping tests” ejecutados y guardados como evidencia.
4. **Data**
   - [ ] NEON contiene catálogos mínimos requeridos (fault_catalog/spares si aplica) y tablas core (customers/contracts/transactions/virtual_accounts).
   - [ ] Odoo tiene catálogo contable y módulo `odoo_corebanking` instalado/configurado.

**Evidencia requerida (carpeta):** `EVIDENCIAS/HU25/00_preflight/*`

---

### 2.2 Flujo del piloto: originación → contrato → pago → conciliación

> Donde se menciona “ID”, guardar siempre el ID nativo del sistema + timestamp.

#### Paso 1 — Alta de prospecto (PWA → BFF → Odoo/NEON)
- Acción:
  - Crear cliente/prospecto (mercado AGS o EDOMEX).
  - Si EDOMEX Route-First: crear Ruta y vincular miembro(s).
- Evidencias:
  - Captura PWA (pantalla de alta).
  - Log BFF de request/response (correlation_id).
  - Registro en Odoo (`res.partner` + `crm.lead`) con IDs.
  - Registro en NEON (customers).

**Evidencia:** `EVIDENCIAS/HU25/01_alta_cliente/*`

#### Paso 2 — KYC Metamap (PWA → BFF → Metamap)
- Acción:
  - Ejecutar verificación KYC real.
- Evidencias:
  - ID de verificación Metamap.
  - Resultado final (approved/review/rejected) y razones (sin exponer PII en repo).
  - Persistencia en NEON y/o Odoo (status KYC).

**Evidencia:** `EVIDENCIAS/HU25/02_kyc/*`

#### Paso 3 — Voice Pattern + HASE (PWA → BFF → scoring)
- Acción:
  - Capturar audio (12 preguntas) y calcular `voice_score`.
  - Calcular HASE final (ponderación 50/30/15/5).
- Evidencias:
  - Payload de scoring (sin audio crudo, sólo hashes/metadata).
  - Resultado: `voice_score`, `hase_score`, tier, flags.
  - Inserción en NEON `hase_scores` (row id) y disponibilidad en cockpit.

**Evidencia:** `EVIDENCIAS/HU25/03_scoring/*`

#### Paso 4 — Configuración + Cotización (PWA → BFF → Odoo)
- Acción:
  - Seleccionar paquete/plan según reglas (AGS vs EDOMEX).
  - Guardar cotización/oportunidad en Odoo.
- Evidencias:
  - Snapshot configurador (PWA).
  - Registro en Odoo (lead/quote) con tasa, plazo, enganche, score.
  - Validaciones de reglas de negocio (logs/flags).

**Evidencia:** `EVIDENCIAS/HU25/04_cotizacion/*`

#### Paso 5 — Contrato y firma Mifiel (PWA → BFF → Mifiel)
- Acción:
  - Generar contrato + anexos (si aplica protección/step-down/adendas).
  - Enviar a firma y completar firma.
- Evidencias:
  - ID del documento en Mifiel, status firmado.
  - PDF final firmado (con PII redacted si se sube a repo; ideal guardar fuera y subir sólo evidencia parcial).
  - Actualización en Odoo (contrato adjunto) y/o NEON (contracts).

**Evidencia:** `EVIDENCIAS/HU25/05_contrato_firma/*`

#### Paso 6 — Cuenta virtual + referencia de pago (FASE9 pasos 2-4)
- Acción:
  - Crear cuenta virtual (Odoo módulo corebanking).
  - Generar referencia Conekta (SPEI/OXXO/tarjeta según reglas).
- Evidencias:
  - ID cuenta virtual Odoo + external_id NEON.
  - Orden/checkout Conekta + referencia.
  - Registro staging (Airtable/NEON staging si aplica).

**Evidencia:** `EVIDENCIAS/HU25/06_cuenta_referencia/*`

#### Paso 7 — Pago real (cliente) + webhook (Conekta → BFF)
- Acción:
  - Ejecutar pago real (ideal monto pequeño de prueba controlada).
  - Recibir webhook `order.paid` (u equivalente).
- Evidencias:
  - Payload webhook (redactado).
  - Firma/verificación del webhook (HMAC) y respuesta 2xx.
  - Encolado a `webhookRetryService` y persistencia.

**Evidencia:** `EVIDENCIAS/HU25/07_pago_webhook/*`

#### Paso 8 — Antifraude/validación + asiento contable (FASE9 pasos 5-7)
- Acción:
  - Validar staging, antifraude y pasar asiento a Odoo:
    - Debit: Banco NEON (101)
    - Credit: Ingreso (405) u otras cuentas según catálogo
  - Registrar transacción en NEON (transactions).
- Evidencias:
  - Registro de validación (pass/fail).
  - `account.move` creado en Odoo con ID + líneas.
  - Row en NEON `transactions` con referencia cruzada.

**Evidencia:** `EVIDENCIAS/HU25/08_asiento_neon/*`

#### Paso 9 — Conciliación vs extracto NEON (FASE9 paso 8)
- Acción:
  - Consumir extracto/statement NEON (Bank API o proceso documentado).
  - Ejecutar conciliación automática (o semiautomática) y marcar match.
- Evidencias:
  - Extracto (redactado) y hash.
  - Resultado conciliación (match/no match + razón).
  - Evidencia visual en Odoo (bank reconciliation) o log.

**Evidencia:** `EVIDENCIAS/HU25/09_conciliacion/*`

#### Paso 10 — Notificación + estado de cuenta (FASE9 pasos 9-11)
- Acción:
  - Notificar “pago recibido”.
  - Generar recibo/estado de cuenta PDF (si aplica) y registrar envío.
- Evidencias:
  - Logs de Twilio/Sendgrid (message id).
  - PDF generado (redactado).
  - Registro de entrega en Odoo/NEON.

**Evidencia:** `EVIDENCIAS/HU25/10_notificaciones_estado_cuenta/*`

#### Paso 11 — Backups + bitácora PLD (FASE9 pasos 13-14)
- Acción:
  - Ejecutar backup automatizado (NEON → S3).
  - Registrar PLD mínimo: operación, cliente, banderas.
- Evidencias:
  - Log/artefacto del backup (ruta S3, checksum).
  - Registro PLD (tabla/log) y alertas si aplica.
  - Prueba de restore (staging) o evidencia de procedimiento.

**Evidencia:** `EVIDENCIAS/HU25/11_backups_pld/*`

---

## 3) Smoke tests obligatorios (antes de cada piloto)

> Guardar outputs en `EVIDENCIAS/HU25/00_preflight/smoke_tests/`

- [ ] `GET /health` (BFF)
- [ ] `GET /docs` o `GET /swagger` (BFF)
- [ ] Odoo: autenticación + `res.partner.search_read` con credenciales productivas.
- [ ] Conekta: crear orden de prueba + validar firma webhook.
- [ ] Mifiel: crear documento de prueba en sandbox + status.
- [ ] Metamap: crear verificación de prueba.
- [ ] NEON DB: query simple + inserción/lectura en tabla de prueba (o `customers`).
- [ ] NEON Bank: request mínimo (token/statement) según integración.

---

## 4) Go / No-Go (criterios de decisión del piloto)

### Go si…
- [ ] Se completan pasos 1-10 sin intervención manual “fuera del sistema” (salvo aprobación operativa).
- [ ] La conciliación funciona y no hay “dinero huérfano”.
- [ ] Hay trazabilidad completa (correlation_id en logs + IDs de sistemas).
- [ ] Backups + runbooks listos.

### No-Go si…
- [ ] Webhooks no confiables o sin firma/idempotencia.
- [ ] No existe conciliación reproducible.
- [ ] Odoo no está listo (catálogo contable / módulo corebanking / asientos).
- [ ] KYC/firma fallan de forma sistemática.
- [ ] No hay evidencia auditable.

---

## 5) Entregables de cierre del piloto

- [ ] Reporte HU25 (1-3 páginas) con:
  - Conteo de pasos exitosos/fallidos
  - Lista de bugs/incidentes
  - KPI de conciliación
  - Recomendación de siguiente iteración
- [ ] Carpeta `EVIDENCIAS/HU25/*` completa (redactada).
- [ ] Checklist HU24/HU25 actualizado (ver `CORE/CHECKLIST_HU24_HU25_OPERATIVO.md`).
