# CORE FASE 9 — Checklist de cierre (para piloto)

> Este checklist *aterriza* los pendientes típicos del cierre FASE9 para HU25.
> Marcar cada punto sólo si existe evidencia.

---

## A) NEON Bank API
- [ ] Token/OAuth2 configurado (staging/prod)
- [ ] Consulta de extractos/estados lista para conciliación
- [ ] (Si aplica) SPEI de prueba con 2FA y límites documentados
- [ ] Manejo de errores (timeouts, 401, rate limit)

**Evidencia:** `EVIDENCIAS/HU25/09_conciliacion/*`

---

## B) Conciliación automática
- [ ] Job programado (cron/queue) para:
  - [ ] descargar extracto NEON
  - [ ] cruzar con staging/Odoo
  - [ ] marcar match / excepciones
- [ ] KPI calculado (match rate, latencia)

**Evidencia:** logs + métricas + screenshot Odoo reconciliation

---

## C) Antifraude / PLD mínimo
- [ ] Reglas mínimas activas (monto, frecuencia, origen, inconsistencias)
- [ ] Bitácora inmutable (tabla o log)
- [ ] Alertas (email/Slack/WhatsApp interno)

**Evidencia:** `EVIDENCIAS/HU25/11_backups_pld/*`

---

## D) Notificaciones
- [ ] Pago recibido
- [ ] Firma pendiente
- [ ] KYC pendiente / rechazado
- [ ] Conciliación fallida (interno)

**Evidencia:** message ids + logs

---

## E) Backups
- [ ] Backup automático (diario) NEON → S3
- [ ] Retención (X días)
- [ ] Restore probado en staging

**Evidencia:** logs + checksum + restore proof

---

## F) Runbooks y operación
- [ ] Runbooks listos (webhooks, conciliación, Odoo, KYC, firma)
- [ ] Roles definidos (on-call)
- [ ] Procedimiento de rollback (parar dispersión / congelar asientos)

**Evidencia:** `CORE/ANEXO_RUNBOOK_INCIDENTES.md` + checklist firmado por operación

---

## G) Seguridad mínima
- [ ] HTTPS y HSTS (si aplica)
- [ ] Secrets en secret manager
- [ ] Rate limiting en webhooks
- [ ] IP allowlisting (si aplica)
- [ ] Auditoría de accesos (logs)

**Evidencia:** config + says + logs
