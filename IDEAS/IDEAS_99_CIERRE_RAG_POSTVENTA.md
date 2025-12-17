# Cierre RAG Postventa (Flowise + Pinecone + Make + NEON) — Checklist operativo

> Meta: pasar de blueprint a ejecución reproducible en staging.

---



## 0) Elegir implementación (Flowise No‑Code vs FastAPI “API‑first”)

Este cierre aplica a dos rutas posibles:

A) Ruta No‑Code (Flowise + Make):
- Flowise arma el RAG y Make orquesta WhatsApp/Twilio, OCR y registros de tickets.

B) Ruta API‑first (repo `agente_postventa`):
- Servicio FastAPI que expone endpoints `/query_hybrid` y webhook `/twilio/whatsapp`.
- RAG híbrido Pinecone + BM25, con memoria por contacto y “casos”/evidencias.
- Observabilidad: `/health`, `/version`, `/metrics` + endpoints admin protegidos.

Recomendación práctica:
- Si ya se va a operar con SLAs + métricas + evidencia por ticket, la ruta B simplifica la operación.
- Si el objetivo es un MVP ultra-rápido con menor ingeniería, la ruta A puede ser suficiente.

## 1) Infra (Flowise)
- [ ] Instancia Flowise desplegada (Render u otro)
- [ ] URL pública + HTTPS
- [ ] Autenticación (API key / basic auth)
- [ ] Variables para OpenAI + Pinecone cargadas

**Prueba:** `GET /api/v1/health` (si existe) o endpoint equivalente.

---

## 2) Pinecone
- [ ] Índice creado (ej. `higer-ssot`)
- [ ] Dimensiones alineadas con modelo de embeddings (ej. 1536 o el que se use)
- [ ] Namespaces (manuales, boletines, procedimientos)

**Prueba:** upsert de 10 chunks + query semántica.

---

## 3) Ingesta de documentos
- [ ] Manuales / PDF / catálogos convertidos a chunks
- [ ] Embeddings generados
- [ ] Upsert a Pinecone

**Evidencia:** conteo de vectores + sample query result.

---

## 4) Conectividad NEON (catálogos)
- [ ] Endpoints `fault_catalog`, `spare_parts`, `spare_stock` responden datos reales
- [ ] Autenticación `X-Neon-Key` (si aplica)
- [ ] Latencia aceptable

**Prueba:** 3 consultas reales desde Flowise o Make.

---

## 5) Make.com (orquestación)
- [ ] Webhook Twilio configurado
- [ ] Router “falla vs refacción”
- [ ] Llamada a OpenAI Vision/OCR (si aplica)
- [ ] Consulta a Flowise (RAG)
- [ ] Registro de ticket (Airtable u Odoo)

**Prueba:** enviar 3 mensajes por WhatsApp (texto + foto) y obtener respuesta correcta.

---

## 6) Cierre
- [ ] Guardar evidencias en `EVIDENCIAS/RAG/*`
- [ ] Documentar costos reales vs estimados
- [ ] Definir métricas: tasa de resolución, latencia, escalamiento a humano
