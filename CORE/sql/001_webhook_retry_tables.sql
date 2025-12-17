-- 001_webhook_retry_tables.sql
-- Persistencia mínima para webhookRetryService (cola + intentos + DLQ) en NEON (PostgreSQL).
-- Objetivo: que los webhooks sean idempotentes, reintentables y recuperables tras deploy/restart.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS webhook_jobs (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider          TEXT NOT NULL,              -- conekta|odoo|gnv|metamap|mifiel|...
  provider_event_id TEXT NOT NULL,              -- id del evento del proveedor (idempotencia)
  job_type          TEXT NOT NULL,              -- CONEKTA_ORDER_PAID, ODOO_INVOICE_POSTED, ...
  status            TEXT NOT NULL DEFAULT 'PENDING', -- PENDING|IN_PROGRESS|SUCCEEDED|FAILED|DLQ
  payload           JSONB NOT NULL,
  correlation_id    TEXT,
  attempts          INT  NOT NULL DEFAULT 0,
  max_attempts      INT  NOT NULL DEFAULT 10,
  next_run_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_error        TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Idempotencia fuerte: un evento del proveedor solo puede entrar una vez a la cola.
CREATE UNIQUE INDEX IF NOT EXISTS ux_webhook_jobs_provider_event
ON webhook_jobs(provider, provider_event_id);

CREATE INDEX IF NOT EXISTS ix_webhook_jobs_runnable
ON webhook_jobs(status, next_run_at);

CREATE TABLE IF NOT EXISTS webhook_attempts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id       UUID NOT NULL REFERENCES webhook_jobs(id) ON DELETE CASCADE,
  attempt_no   INT  NOT NULL,
  started_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at  TIMESTAMPTZ,
  ok           BOOLEAN,
  duration_ms  INT,
  error        TEXT,
  worker_id    TEXT
);

CREATE INDEX IF NOT EXISTS ix_webhook_attempts_job
ON webhook_attempts(job_id, attempt_no);

CREATE TABLE IF NOT EXISTS webhook_dlq (
  job_id     UUID PRIMARY KEY REFERENCES webhook_jobs(id) ON DELETE CASCADE,
  moved_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  reason     TEXT
);

-- Conveniencia: trigger simple para updated_at (opcional; implementar en app si no usas triggers)
-- CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
-- BEGIN
--   NEW.updated_at = now();
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
-- DROP TRIGGER IF EXISTS tr_webhook_jobs_updated_at ON webhook_jobs;
-- CREATE TRIGGER tr_webhook_jobs_updated_at BEFORE UPDATE ON webhook_jobs
-- FOR EACH ROW EXECUTE FUNCTION set_updated_at();
