# ANEXO — PWA: Realidad y avance (pwa_angular_v5)

1. Propósito

- Documentar, de forma quirúrgica, el estado REAL del frontend PWA (Angular) en el repositorio de código pwa_angular_v5.
- Convertir ese estado en:
  a) un mapa de paridad HU #01–#25,
  b) un checklist accionable para HU24/HU25,
  c) cambios explícitos que la wiki debe reflejar (sin suposiciones).

2. Fuente de verdad

Repositorio (código real):
- GitHub: josuehernandeztapia/pwa_angular_v5

Archivos “punto cero” (donde vive la verdad de la app):
- Rutas: src/app/app.routes.ts
- Feature flags + endpoints + AVI config + finanzas (IRR/TANDA caps): src/environments/environment.base.ts
- Bootstrap: src/main.ts

Nota operativa importante
- En el repo pwa_angular_v5 existen referencias en el README a docs/TECHNICAL_GUIDE.md, docs/QA_GUIDE.md, docs/navigation.md, docs/pwa-features.md y a CLONE-INSTRUCTIONS.md/CHANGELOG.md.
- En el árbol del repo que se observa públicamente, estos archivos NO están presentes (404). Por lo tanto, el source-of-truth debe considerarse el código (routes + environment) y no esos links.

3. Cómo correr la PWA (local) y qué implica para staging

Comandos (según README del repo pwa_angular_v5):
- npm ci --legacy-peer-deps
- npm run start:real    (puerto 4301, pensado para BFF real)
- npm start             (puerto 4300, modo estándar)
- npm run build:prod
- npm run serve:prod

Conectividad backend
- Base API en dev (por defecto): environment.apiUrl = http://localhost:3000/api
- Implicación: la PWA espera un BFF en el puerto 3000 exponiendo /api/* (y rutas /api/bff/* para integraciones)

Riesgo operacional (staging/prod)
- El entorno base define enableMockData = true y además contempla un override global:
  - globalThis.__USE_MOCK_DATA__ === true  → fuerza useMockData
- HU24/HU25 REQUIEREN que staging/prod tengan mocks deshabilitados o aislados. Esto debe ser una “puerta” (gate): si mocks activos, HU24/HU25 no cuentan como cerradas.

4. Mapa de rutas REAL (src/app/app.routes.ts)

4.1 Rutas core (siempre presentes)

Autenticación
- /login
- /register
- /verify-email

Núcleo
- /dashboard
- /onboarding
- /nueva-oportunidad

Documentos y contratos
- /documentos
  - Protegido por guards: AuthGuard + AviCompletedGuard + PlazoGuard + TandaValidGuard + ProtectionRequiredGuard
  - Implicación: el flujo de documentos no es “standalone”; depende de que AVI (voz) esté completado y que el caso/término/tanda/protección cumplan condiciones.
- /document-upload  (alias → /documentos)
- /contratos/generacion
  - Protegido por AuthGuard + ContractReadyGuard

Cotizador
- /cotizador
- /cotizador/ags-individual
- /cotizador/edomex-colectivo
- /cotizadores (alias → /cotizador)

Simulador
- /simulador
- /simulador/ags-ahorro
- /simulador/edomex-individual
- /simulador/tanda-colectiva
- /simuladores (alias → /simulador)

Clientes
- /clientes
- /clientes/nuevo
- /clientes/:id
- /clientes/:id/edit

Operaciones / entregas / GNV
- /entregas
- /entregas/:id
- /gnv

Ops (centro de operaciones)
- /ops/deliveries
- /ops/import-tracker
- /ops/gnv-health
- /ops/deliveries/:id
- /ops/triggers

IMPORTANTE (quirúrgico)
- En el route map se observa duplicada la ruta /ops/gnv-health dos veces. Esto no rompe producción, pero es una señal de deuda técnica y debe corregirse.

Tracking (vista cliente)
- /tracking/client/:clientId

Otras rutas core
- /expedientes
- /proteccion
- /oportunidades
- /reportes
- /productos

Configuración
- /configuracion
- /configuracion/politicas
- /flow-builder (condicional por flag)
- /configuracion/flow-builder (condicional por flag)
- /perfil (condicional por flag)

Errores
- /offline
- /404
- /unauthorized
- wildcard: ** (redirige a /404)

4.2 Rutas condicionales (feature flags / roles)

LAB / Backoffice (si enableLabs o enableTandaLab)
- /lab/tanda-enhanced
- /lab/tanda-consensus

Postventa Wizard (si enablePostventa o enablePostSalesWizard)
- /postventa/wizard
  - Guard: AuthGuard + ContractValidGuard

Integraciones (si enableIntegrationsConfig)
- /integraciones

Administración (si enableAdminConfig)
- /administracion
  - Guard: AuthGuard + RoleGuard (roles: admin)

Claims (si enableClaimsModule)
- /claims
  - Guard: AuthGuard + RoleGuard + FeatureFlagGuard

QA tools (si enableQaTools)
- /qa/monitoring
  - Guard: AuthGuard + RoleGuard + FeatureFlagGuard

Usage (si enableUsageModule)
- /usage

4.3 Rutas “preview” (sin guard)

- /preview/cotizador
- /preview/simulador
- /preview/proteccion

Nota:
- El código indica explícitamente que estas rutas son para validaciones manuales y no deben exponerse en producción real.
- Acción recomendada: deshabilitarlas por build config (prod) o detrás de flag.

5. Feature flags y configuración REAL (src/environments/environment.base.ts)

5.1 Configuración API

- apiUrl: http://localhost:3000/api
- api (paths BFF):
  - flows: /bff/flows
  - postventa: /bff/postventa
  - quotes: /bff/odoo/quotes
  - users: /bff/users
  - labs: /bff/lab

- endpoints (app endpoints):
  - auth: /auth
  - clients: /clients
  - quotes: /quotes
  - scenarios: /scenarios
  - documents: /documents
  - payments: /payments
  - reports: /reports

Implicación:
- La PWA está pensada para consumir el backend vía /api/* y /api/bff/*.
- Para HU24, se recomienda agregar (o documentar) explícitamente un endpoint /health/integrations consumible desde la PWA para “IntegrationsStatus”.

5.2 Feature flags (valores base observados)

Nota: estos valores son “base” (dev). Staging/prod deben sobreescribir.

Flags que impactan HU24/HU25 directamente:
- enableMockData: true
- enableOdooQuoteBff: true
- enableGnvBff: true
- enableKibanHase: true
- enableKycBff: true
- enablePaymentsBff: true
- enableContractsBff: true
- enableAutomationBff: true
- enableRiskBff: true
- enableDeliveryBff: true

Flags que exponen módulos (riesgo de superficie si no se controlan):
- enableLabs: true
- enableTandaLab: true
- enablePostventa: true
- enablePostSalesWizard: true
- enableClaimsModule: true
- enableAdminConfig: true
- enableFlowBuilder: true
- enablePerfil: true
- enableQaTools: true

Flags apagados en base (pero relevantes):
- enableIntegrationsConfig: false
- enableUsageModule: false
- enableRemoteConfig: false

5.3 AVI / Voz (config operativa)

- El environment define un bloque avi con:
  - decisionProfile: conservative
  - thresholds: GO_MIN 0.78, NOGO_MAX 0.55 (conservador)
  - lexicalBoosts: tokens evasivos con multiplicador 1.5
  - estrés/voiceAnalysis/realtime transcription: true

Implicación:
- El gating de “AviCompletedGuard” y el módulo de voz deben alinearse con la wiki (Voice Pattern 12 preguntas), y se deben definir evidencias en HU25:
  - audio_id / request_id
  - voiceScore/flags/decision
  - persistencia (NEON hase_scores o tabla equivalente)

5.4 Finanzas (IRR targets + caps TANDA)

- irrToleranceBps: 50
- irrTargets.bySku incluye:
  - H6C_STD: 0.255
  - H6C_PREMIUM: 0.299
- tandaCaps:
  - rescueCapPerMonth: 1.0
  - freezeMaxPct: 0.2
  - freezeMaxMonths: 2
  - activeThreshold: 0.8

Implicación:
- La PWA contiene “política” embebida que debe estar alineada con CORE/CORE_FASE3C_REGLAS_NEGOCIO.md y LOGICA_MATEMATICA.md (TIR mínima por mercado/producto).
- Si estas políticas se van a mover a “remote config”, debe cerrarse la brecha: hoy enableRemoteConfig está false.

6. Guards (gating) y dependencia de estados

Guards referenciados en el route map:
- AuthGuard
- AviCompletedGuard
- FeatureFlagGuard
- PlazoGuard
- ProtectionRequiredGuard
- RoleGuard
- TandaValidGuard
- ContractReadyGuard
- ContractValidGuard
- DeliveryGuard

Implicación operativa:
- Para cerrar HU24/HU25, la evidencia no es solo “pantalla existe”. Debe evidenciarse que los guards pasan usando estados persistidos (NEON/Odoo) y no flags locales.
- Ejemplo concreto:
  - /documentos no debe permitir avanzar si no existe scoring (AVI completo) y si el plazo no es válido.

7. Paridad HU #01–#25 (vista quirúrgica)

Notas:
- Los nombres exactos de HU viven en CORE/CORE_FASE3B_HISTORIAS_USUARIO.md (wiki). Aquí se mapea por dominios/épicas.

HU01–HU04 (núcleo / cockpit asesor)
- Implementación observada:
  - /dashboard
  - /clientes/* (list, create, detail, edit)
  - /oportunidades
  - /nueva-oportunidad
- Estado sugerido: PARCIAL (UI + navegación + estructura; faltan integraciones reales end-to-end para “cockpit 360” contra Odoo/NEON)

HU05–HU06 (Route-First: rutas + miembros)
- Implementación observada:
  - No se observan rutas explícitas “/rutas” en el mapa.
  - Podría estar embebido en /clientes o /onboarding según UI.
- Estado sugerido: NO CONFIRMADO (requiere verificar componentes internos + persistencia Odoo)

HU07–HU12 (motor financiero: paquetes, configurador, cotizador, pagos)
- Implementación observada:
  - /cotizador (AGS individual, EdoMex colectivo)
  - /simulador (AGS ahorro, EdoMex individual, TANDA colectiva)
  - /productos
  - /reportes
- Estado sugerido: PARCIAL
  - Hay ruteo y pantallas dedicadas; falta confirmar persistencia/IDs en Odoo (quote_id, lead_id) y validaciones completas del negocio.

HU13–HU14 (expediente digital + validaciones)
- Implementación observada:
  - /documentos (flow) + guards múltiples
  - /expedientes
  - /contratos/generacion
- Estado sugerido: PARCIAL
  - Existen flujos; falta confirmar upload S3 real + OCR real + firma Mifiel real, y que el gating se base en datos reales.

HU15–HU20 (conversiones, TANDA, alertas, estados de cuenta)
- Implementación observada:
  - simulador de TANDA y módulos LAB (tanda enhanced/consensus)
  - /reportes (posible estados de cuenta)
  - /proteccion
  - /ops/triggers (monitor de triggers)
- Estado sugerido: PARCIAL
  - Hay pantalla/route; falta validar wiring contra core bancario (Odoo ledger + conciliación) y triggers automáticos.

HU21–HU23 (operación, alertas, tracking, entregas)
- Implementación observada:
  - /entregas, /ops/deliveries, /ops/import-tracker
  - /tracking/client/:clientId
  - /gnv y /ops/gnv-health
- Estado sugerido: PARCIAL
  - Existen módulos de operaciones; falta confirmar backend real (enableDeliveryBff/enableGnvBff) y dataset real (NEON).

HU24 (integraciones reales)
- Implementación observada:
  - Existe route /integraciones (condicional) y múltiples flags enable*Bff true en environment base.
- Estado sugerido: DEPENDE DE BACKEND
  - La PWA ya está “lista para conectar”, pero HU24 exige que el backend responda (Odoo/Conekta/Metamap/Mifiel/GNV/KIBAN/NEON Bank/OpenAI).

HU25 (piloto end-to-end)
- La PWA debe aportar evidencias de navegación real y captura de evidencias (IDs, screenshots) siguiendo CORE/CORE_FASE10_PILOTO_OPERATIVO.md.
- Estado sugerido: POR EJECUTAR (si no existe un piloto con evidencia).

8. Acciones quirúrgicas recomendadas para alinear PWA ↔ wiki (y cerrar HU24/HU25)

Acción P0 (bloqueadores)
1) Apagar mocks en staging/prod
- Forzar enableMockData = false
- Bloquear el override globalThis.__USE_MOCK_DATA__ en builds staging/prod
- Evidencia: screenshot de “Integraciones OK” + logs BFF con requests reales

2) Agregar UI “IntegrationsStatus” (si no existe) o conectar /integraciones a /health/integrations
- Definir exactamente qué integra HU24 (Odoo/Conekta/Metamap/Mifiel/GNV/KIBAN/NEON/OpenAI)
- Mostrar estado ✅/❌ por integración
- Bloquear CTAs críticos si alguna integración obligatoria está ❌

3) Corregir duplicado de rutas /ops/gnv-health
- Evitar inconsistencias y warnings de router

Acción P1 (cierre operativo)
4) Evidence-first: capturas y logs por cada paso HU25
- /dashboard → cliente → scoring → documentos → contratos → pago → reportes
- Guardar en EVIDENCIAS/HU25/ (IDs Odoo/Conekta/Metamap/Mifiel/NEON)

5) Alinear políticas de IRR/TIR
- Verificar coherencia: environment.finance.irrTargets (0.255/0.299) vs wiki (25.5% AGS, 29.9% EDOMEX)
- Si el SKU premium usa 0.299, documentar en reglas y/o mapear por mercado

