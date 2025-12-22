# ANEXO — Implementaciones IA externas a la wiki (referencias y mapeo)

Objetivo
- Mantener explícito en la wiki qué partes de "IA" ya existen como implementación (código runnable) fuera del repositorio wiki_conductores, para evitar que el estado real se quede "implícito" o sólo en chats.

1) Repo: agente_postventa (Higer RAG API, FastAPI)
Qué es
- Servicio FastAPI "API-first" para postventa Higer. Enfocado en endpoints HTTP, observabilidad y operación real.
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

Qué falta para "cerrar" la integración con la plataforma Conductores
- Definir el punto de acople definitivo:
  A) Make.com invoca /query_hybrid y reenvía respuesta a WhatsApp
  B) El webhook /twilio/whatsapp recibe directo (Make opcional)
- Enlazar "casos"/tickets con Odoo/Airtable/NEON (ID de caso, adjuntos, evidencia, estatus) y documentar el payload final.
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

Qué falta para "cerrar" la integración con la plataforma Conductores
- Alinear nombres/rutas de endpoints (wiki vs BFF real) y publicar contrato final (Swagger/ OpenAPI).
- Definir set "operativo" (12 preguntas) como subset oficial del dataset ampliado y versionarlo.
- Evidencia HU24/HU25: al menos 1 evaluación real con audio + decisión GO/REVIEW/NO-GO persistida en NEON (hase_scores.voice_score) y visible en Cockpit.

3) **NUEVO - Repo: rag-pinecone (Enhanced Risk Scoring Engine)**
Qué es
- Sistema de scoring de riesgo enriquecido con telemetría Geotab-API y validación matemática.
- Implementa arquitectura multi-agent (HASE, PIA, Guardian) con Smart Consolidation anti-spam.
- Incluye TIR Equilibrium Engine enriquecido con behavioral data para decisiones de protección.

**Componentes Principales:**
- **Multi-Agent Architecture**: HASE (default risk), PIA (portfolio risk), Guardian (operational risk)
- **Enhanced Scoring**: Hybrid scoring con validación matemática (+25.7% mejora en PIA)
- **Smart Consolidation**: Sistema anti-duplicación con agent hierarchy y cooldown periods
- **TIR Integration**: Protection scenarios basados en behavioral telemetry data
- **LLM Notifications**: Sistema de alertas inteligente con context enrichment

**Arquitectura Técnica:**
```
Geotab API → Raw Data → Enrichment Pipeline → Enhanced Features
     ↓
Enhanced Features → Agent Scoring → Risk Assessment → Smart Consolidation
     ↓
Smart Consolidation → TIR Equilibrium → Protection Scenarios → LLM Notifications
```

**Features Implementados (Diciembre 2025):**
- **Mathematical Validation**: Grid search optimization de pesos híbridos
- **Telemetry Integration**: 150+ variables de comportamiento de manejo
- **Enhanced Agents**: HASE 70/30 (optimal), PIA 80/20 (+25.7% mejora), Guardian operational stress
- **Anti-Spam Logic**: Cooldown periods diferenciados (default: 6h, portfolio: 4h, operational: 2h)
- **TIR Enhancement**: Protection policies basadas en safety_risk_score y operational_risk_score

**Scripts de Operación:**
- `scripts/ops/enrich_all_agents.py` → Pipeline unificado de enriquecimiento
- `scripts/validation/validate_hybrid_weights_simple.py` → Validación matemática
- `agents/*/scripts/*_llm_notifier.py` → Sistema de notificaciones LLM
- `agents/shared/smart_consolidation.py` → Coordinación anti-spam

**Integración con TIR Equilibrium:**
- **Enhanced ProtectionContext**: Scores granulares (safety_risk_score, operational_risk_score, behavioral_enhancement_score)
- **Policy Overrides**: Ajustes automáticos de protection options basados en behavioral patterns
- **Helper Functions**: `create_enhanced_protection_context()`, `evaluate_scenarios_enhanced()`

Dónde se documenta en la wiki
- **CORE/ANEXO_LLMOPS_AGENTOPS.md** (Multi-agent orchestration patterns)
- **IDEAS/SCORING_ALGORITHMS.md** (Mathematical validation methodology - NUEVO)
- **IDEAS/TELEMETRY_INTEGRATION.md** (Geotab-API integration patterns - NUEVO)
- **LOGICA_MATEMATICA.md** (actualización con enhanced scoring results)

Qué falta para "cerrar" la integración con la plataforma Conductores
- **Production deployment** del enhanced scoring engine en ambiente real
- **A/B testing** con split traffic para validar mejoras en vivo
- **Monitoring dashboard** para métricas de enriquecimiento y consolidation
- **Integration** con agente_postventa para context enrichment en customer service
- **Real-time streaming** de telemetría para scoring en tiempo real

**Status (Diciembre 2025):** ✅ **Implementación completa con validación matemática**
- Enhanced agents funcionando con backward compatibility
- Smart Consolidation activo para prevención de spam
- TIR Equilibrium engine enriquecido con behavioral data
- Sistema listo para production deployment

4) Recomendación de consistencia (SSOT documental)
- La wiki describe arquitectura, reglas de negocio, HU y runbooks.
- Los repos externos son la implementación runnable.
- Cada vez que exista un avance en repos externos (endpoints nuevos, payloads, variables), se debe reflejar explícitamente en:
  - README_ALLIN.md (visión general)
  - IDEAS_18 / IDEAS_99 (postventa RAG)
  - LOGICA_MATEMATICA.md (voice/hase) y/o anexos de integración BFF
  - **NUEVOS**: IDEAS/SCORING_ALGORITHMS.md, IDEAS/TELEMETRY_INTEGRATION.md (enhanced risk scoring)

4) **NUEVO - Repo: pwa_angular_v5 (/web - Angular PWA Enterprise)**
Qué es
- PWA Angular 17+ con arquitectura enterprise moderna en directorio `/web`
- 50+ módulos especializados con testing infrastructure completo
- Demo system avanzado con 10+ scenario seeds y analytics dashboard
- Signal-based reactive state management con quality gates enterprise

**Componentes Principales:**
- **Core Business**: Dashboard, Clientes, Cotizador, Simulador, Protección
- **Advanced Systems**: AVI Interview, KYC biométrico, Document Center con OCR
- **Demo Framework**: Scenario testing con event tracking y performance metrics
- **Quality Infrastructure**: 150+ test cases, E2E Playwright, accessibility compliance

**Arquitectura Técnica:**
```
Angular 17+ → Standalone Components → Signal State → PWA Features
     ↓
Demo System → Scenario Seeds → Analytics Dashboard → Quality Gates
     ↓
AVI/Voice → KYC Biometric → TIR Protection → Enhanced Integration Ready
```

**Features Implementados (Diciembre 2025):**
- **Enterprise Architecture**: `/web` codebase con CI/CD pipeline completo
- **Quality Gates**: >90% coverage, <2.6MB bundle, >95 Lighthouse score
- **Demo System**: 10+ scenarios (AVI Test, KYC Test, Finanzas What-If, Protección)
- **Integration Ready**: Enhanced scoring compatible, Smart Consolidation ready
- **PWA Compliance**: Service worker, offline support, responsive design

**Scripts de Operación:**
- `cd web && npm run ci:qa` → Full quality pipeline validation
- `cd web && npm run ci:test:stores` → Core business logic testing
- `cd web && npm run ci:playwright` → E2E cross-browser testing
- `cd web && npm start` → Development server port 4200

**Integration con Enhanced Features:**
- **Enhanced Scoring**: Signal-based state ready para mathematical optimization
- **Smart Consolidation**: Service layer compatible con anti-spam logic
- **TIR/AVI Enhancement**: Protection module y voice system integration points
- **Real-time Telemetry**: Analytics infrastructure para streaming data

Dónde se documenta en la wiki
- **README_ALLIN.md** (referencia básica del repository)
- **ANEXO_PWA_IMPLEMENTACION.md** (guía técnica enterprise completa - NUEVO)

Qué falta para "cerrar" la integración con la plataforma Conductores
- **Enhanced Features Deployment** en PWA production environment
- **Mathematical Scoring Integration** con optimized weights deployment
- **Smart Consolidation** activation en production workflow
- **Real-time Telemetry** streaming connection con enhanced risk engine
- **Cross-platform Integration** con agente_postventa y rag-pinecone systems

**Status (Diciembre 2025):** ✅ **Production Ready Enterprise PWA**
- Angular 17+ architecture con comprehensive testing
- Demo system completo para validation y training
- Enhanced features integration points ready
- Quality gates enterprise establecidos y funcionando

---

**Actualizado**: Diciembre 22, 2025 - PWA Angular v5 Enterprise Documentation Complete + Enhanced Risk Scoring Engine implementación completa