# ANEXO — Implementaciones IA externas a la wiki (referencias y mapeo)

Objetivo
- Mantener explícito en la wiki qué partes de “IA” ya existen como implementación (código runnable) fuera del repositorio wiki_conductores, para evitar que el estado real se quede “implícito” o sólo en chats.

1) Repo: agente_postventa (Higer RAG API, FastAPI)
Qué es
- Servicio FastAPI “API-first” para postventa Higer. Enfocado en endpoints HTTP, observabilidad y operación real.
- Implementa RAG híbrido (Pinecone + BM25) + memoria por contacto + gestión de casos/evidencias y playbooks por categoría.
- Incluye pipeline de medios (OCR/vision, transcripción, clasificación) para enriquecer el contexto.

Interfaz (alto nivel)
- POST /query           → RAG básico (sin memoria/casos)
- POST /query_hybrid    → RAG híbrido con memoria/casos + playbooks
- POST /twilio/whatsapp → webhook WhatsApp oficial (texto + medios)
- GET  /health, /version, /metrics → diagnóstico/observabilidad
- Endpoints admin protegidos para auditar casos e índices

Dónde se documenta en la wiki
- IDEAS/IDEAS_18_AGENTE_POSTVENTA_RAG.md (blueprint y ahora referencia al camino API-first)
- IDEAS/IDEAS_99_CIERRE_RAG_POSTVENTA.md (checklist operativo)

Qué falta para “cerrar” la integración con la plataforma Conductores
- Definir el punto de acople definitivo:
  A) Make.com invoca /query_hybrid y reenvía respuesta a WhatsApp
  B) El webhook /twilio/whatsapp recibe directo (Make opcional)
- Enlazar “casos”/tickets con Odoo/Airtable/NEON (ID de caso, adjuntos, evidencia, estatus) y documentar el payload final.
- Estándar de evidencias (para auditoría): request/response, IDs de ticket, logs de /metrics y registro en Odoo/Airtable.

2) Repo: avi_lab (PWA de laboratorio para voz/AVI)
Qué es
- PWA independiente para experimentar, probar y entrenar el algoritmo de voz.
- Incluye dataset ampliado de 55 preguntas AVI (subset de 12 críticas + set alto estrés) y tooling para exportar/validar.

Interfaz esperada
- En el flujo demo, la PWA captura audio y lo envía a un endpoint del BFF para evaluación (por ejemplo /v1/voice/evaluate-audio) y muestra voiceScore/flags/decision.

Dónde se documenta en la wiki
- LOGICA_MATEMATICA.md (Voice Pattern como flujo estándar de 12 preguntas; nota sobre dataset ampliado)
- README_ALLIN.md (sección KIBAN/HASE + Voice Pattern con nota de implementación/lab)

Qué falta para “cerrar” la integración con la plataforma Conductores
- Alinear nombres/rutas de endpoints (wiki vs BFF real) y publicar contrato final (Swagger/ OpenAPI).
- Definir set “operativo” (12 preguntas) como subset oficial del dataset ampliado y versionarlo.
- Evidencia HU24/HU25: al menos 1 evaluación real con audio + decisión GO/REVIEW/NO-GO persistida en NEON (hase_scores.voice_score) y visible en Cockpit.

3) Recomendación de consistencia (SSOT documental)
- La wiki describe arquitectura, reglas de negocio, HU y runbooks.
- Los repos externos son la implementación runnable.
- Cada vez que exista un avance en repos externos (endpoints nuevos, payloads, variables), se debe reflejar explícitamente en:
  - README_ALLIN.md (visión general)
  - IDEAS_18 / IDEAS_99 (postventa RAG)
  - LOGICA_MATEMATICA.md (voice/hase) y/o anexos de integración BFF

