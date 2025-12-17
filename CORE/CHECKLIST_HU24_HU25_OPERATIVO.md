# Checklist Operativo — HU24 / HU25 (Integraciones reales + Cliente piloto)

> Objetivo: convertir HU24/HU25 en evidencia ejecutable.  
> Formato: cada ítem requiere **(a)** prueba técnica y **(b)** evidencia guardada.

---

## HU24 — Integraciones reales (Definition of Done)

### A) Configuración de secrets (BFF/PWA/Jobs)
- [ ] `.env`/secrets cargados en el entorno (no commit)  
  **Evidencia:** screenshot de variables (redactado) + `GET /health/config` (si existe)
- [ ] Validación de config en arranque (si falta algo crítico → fail-fast)  
  **Evidencia:** log de arranque + caso negativo (staging) mostrando rechazo

### B) Odoo (CRM + Accounting + Corebanking)
- [ ] Autenticación XML-RPC/JSON-RPC operativa en staging/prod
- [ ] CRUD mínimo:
  - [ ] `res.partner.create`
  - [ ] `crm.lead.create`
  - [ ] `account.move.create` + `action_post`
- [ ] Módulo `odoo_corebanking` instalado y configurado:
  - [ ] Modelo `virtual_account` operando
  - [ ] Catálogo contable mínimo (101 Banco NEON / 405 Ingreso / 201 Proveedores)
- [ ] Soporta “cuenta analítica” para clientes/rutas/TANDA  
**Evidencia:** IDs en Odoo + capturas del UI Odoo

### C) Conekta (pagos + webhooks)
- [ ] Crear orden/checkout real (sandbox/prod)
- [ ] Webhook `order.paid` entra al BFF con:
  - [ ] validación de firma
  - [ ] idempotencia (mismo evento no duplica)
  - [ ] reintentos + DLQ en caso de error
- [ ] Persistencia: evento + transacción quedan en NEON/Odoo (según FASE9)  
**Evidencia:** payload redactado + logs + IDs (order_id, payment_id)

### D) Metamap (KYC)
- [ ] Crear verificación
- [ ] Recibir resultado (callback/webhook o polling)
- [ ] Persistir status + reasons (sin PII)  
**Evidencia:** verification_id + status final + row en NEON/Odoo

### E) Mifiel (firmas)
- [ ] Generar contrato (PDF) y enviarlo a firma
- [ ] Completar firma
- [ ] Guardar PDF firmado y asociarlo a Odoo/NEON  
**Evidencia:** document_id + status + PDF (redactado) + registro en Odoo

### F) KIBAN/HASE (scoring) + Voice Pattern
- [ ] Endpoint scoring responde y genera:
  - [ ] `voice_score`
  - [ ] `telemetry_score` (si aplica)
  - [ ] `financial_score` (si aplica)
  - [ ] `bureau_score` (si aplica)
  - [ ] `hase_score` final + tier
- [ ] Persistencia en `hase_scores` (NEON) con JSONB `factors` auditables  
**Evidencia:** row id + JSON (redactado) + cockpit mostrando tier

### G) GNV / Telemática (mínimo viable)
- [ ] Ingesta mínima (aunque sea batch) y lectura desde NEON
- [ ] Endpoints `/v1/*` devuelven datos reales (no vacíos) para:
  - [ ] consumption / historics (si aplica)
  - [ ] catálogos / equivalencias  
**Evidencia:** query + respuesta endpoint + row count

### H) NEON Database & DataOps
- [ ] Conexión desde BFF + scripts/jods
- [ ] Backups automáticos + verificación de restore (staging)
- [ ] Particionamiento/retención según documento  
**Evidencia:** logs + artefactos backup + checksum

### I) NEON Bank API (si entra en piloto)
- [ ] Token/OAuth2 funcional
- [ ] Consulta de extractos/estados para conciliación
- [ ] (Opcional) SPEI/transfer de prueba con 2FA y límites  
**Evidencia:** request/response redactado + logs

### J) Observabilidad (mínimo)
- [ ] correlation_id por request (PWA→BFF→Odoo/externos)
- [ ] dashboard/log search para:
  - [ ] webhooks
  - [ ] conciliación
  - [ ] fallas de integraciones  
**Evidencia:** screenshot de logs filtrados + ejemplo trazado

---

## HU25 — Cliente piloto (Definition of Done)

### 1) Ejecución E2E (una unidad mínima)
- [ ] Alta de cliente y/o ruta (según mercado)
- [ ] KYC Metamap completado
- [ ] HASE + Voice ejecutados y visibles
- [ ] Cotización guardada en Odoo
- [ ] Contrato firmado en Mifiel
- [ ] Cuenta virtual + referencia de pago emitida
- [ ] Pago real recibido (monto controlado)
- [ ] Webhook procesado → asiento contable en Odoo
- [ ] Transacción registrada en NEON
- [ ] Conciliación contra extracto NEON realizada
- [ ] Notificación enviada + recibo/estado de cuenta generado
- [ ] Backup + registro PLD completados

### 2) Evidencias mínimas (carpeta)
- [ ] `EVIDENCIAS/HU25/00_preflight/`
- [ ] `EVIDENCIAS/HU25/01_alta_cliente/`
- [ ] `EVIDENCIAS/HU25/02_kyc/`
- [ ] `EVIDENCIAS/HU25/03_scoring/`
- [ ] `EVIDENCIAS/HU25/04_cotizacion/`
- [ ] `EVIDENCIAS/HU25/05_contrato_firma/`
- [ ] `EVIDENCIAS/HU25/06_cuenta_referencia/`
- [ ] `EVIDENCIAS/HU25/07_pago_webhook/`
- [ ] `EVIDENCIAS/HU25/08_asiento_neon/`
- [ ] `EVIDENCIAS/HU25/09_conciliacion/`
- [ ] `EVIDENCIAS/HU25/10_notificaciones_estado_cuenta/`
- [ ] `EVIDENCIAS/HU25/11_backups_pld/`

### 3) Cierre HU25 (reporte)
- [ ] Resumen ejecutivo (qué funcionó / qué no)
- [ ] Lista priorizada de bugs (P0/P1/P2)
- [ ] KPI: conciliación (% match, latencia)
- [ ] Recomendación Go/No-Go para ampliar piloto
