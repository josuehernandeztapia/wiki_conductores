# Cierre RAG Postventa (Flowise + Pinecone + Make + NEON) — Checklist operativo

> Meta: pasar de blueprint a ejecución reproducible en staging.

---

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
