# CORE/scripts y CORE/sql

Esta carpeta contiene artefactos *operativos* para cerrar HU24/HU25:

## scripts/
- `preflight_hu24_hu25.sh`: valida health + integraciones en staging antes de correr HU25.

## sql/
- `001_webhook_retry_tables.sql`: DDL mínimo para persistir cola + intentos + DLQ de webhooks (idempotencia + reintentos).

> Importante: los SQL deben ejecutarse en NEON (staging/prod) con las credenciales correctas.
