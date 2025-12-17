# Runbooks Operativos — Incidentes típicos (Piloto)

> Objetivo: reducir MTTR durante HU25 y dejar evidencia trazable.

Cada incidente debe registrar:
- timestamp
- correlation_id (si existe)
- IDs externos (Conekta/Mifiel/Metamap/Odoo/NEON)
- acción correctiva
- prevención (post-mortem breve)

---

## 1) Webhook de Conekta no llega

**Síntomas**
- Pago realizado, pero PWA no refleja “pagado”.
- No hay evento `order.paid` en logs.

**Chequeos**
1. Revisar en Conekta:
   - URL configurada
   - status 2xx / reintentos
2. Revisar logs del BFF:
   - endpoint correcto
   - validación de firma (¿falló HMAC?)
3. Revisar red/infra:
   - firewall/allowlist IP
   - TLS/cert

**Acciones inmediatas**
- Reenviar webhook desde Conekta (si existe opción).
- Ejecutar endpoint interno “replay” (si existe) o job de “pull” por order_id.

**Prevención**
- Idempotencia por `event_id`.
- Alertas si tasa de webhooks fallidos > X%.

---

## 2) Asiento contable falla en Odoo

**Síntomas**
- Webhook llega, pero no se crea `account.move`.
- DLQ crece en `webhookRetryService`.

**Chequeos**
- Credenciales Odoo (auth OK)
- Catálogo de cuentas (101/405) existe
- Permisos de usuario para contabilidad
- Payload completo (analytic account, partner_id, journal_id)

**Acciones inmediatas**
- Reintentar desde cola.
- Si error es por catálogo: crear cuenta faltante y reintentar.

**Prevención**
- “Config check” al arrancar: validar cuentas/journals requeridos.
- Test de posting diario en staging.

---

## 3) Conciliación no encuentra match (dinero “huérfano”)

**Síntomas**
- Hay transacción en Odoo o staging, pero no cuadra con extracto NEON.
- KPI conciliación < 95%.

**Chequeos**
- Moneda/decimales
- Referencia SPEI/OXXO
- Fechas (timezone)
- Duplicados (idempotencia)

**Acciones inmediatas**
- Marcar excepción y abrir caso (Case) con evidencia.
- Ejecutar conciliación manual controlada y documentar.

**Prevención**
- Normalización de referencias.
- Hash único por (monto, referencia, fecha, cuenta).

---

## 4) KYC Metamap queda “en progreso” indefinidamente

**Chequeos**
- Webhook/callback configurado
- Rate limits
- Revisión manual pendiente

**Acciones**
- Polling por verification_id (si es soportado)
- Escalar a operación para revisión manual

**Prevención**
- Timer automático: si > X min en “pending” → alerta + fallback manual

---

## 5) Firma Mifiel falla

**Chequeos**
- PDF válido
- Plantilla/contrato sin campos corruptos
- Webhook secreto correcto

**Acciones**
- Regenerar documento
- Enviar nuevo link al firmante

**Prevención**
- Validación PDF antes de enviar a Mifiel
- Control de versiones de plantillas

---

## 6) Scoring (HASE/Voice) no responde o no persiste

**Chequeos**
- Servicio scoring arriba
- Modelos OpenAI disponibles (si usa transcripción/embeddings)
- NEON accesible (insert en `hase_scores`)

**Acciones**
- Degradación: permitir “REVIEW” y forzar documentación extra
- Cola de reintento para persistencia

**Prevención**
- Circuit breaker + retries
- Métricas de latencia/errores por proveedor

---

## 7) Backups no se ejecutan

**Chequeos**
- Credenciales S3
- `pg_dump` disponible en runner
- Espacio / permisos

**Acciones**
- Ejecutar backup manual
- Verificar integridad (checksum)

**Prevención**
- Alerta si no hay backup en 24h
- Prueba semanal de restore en staging
