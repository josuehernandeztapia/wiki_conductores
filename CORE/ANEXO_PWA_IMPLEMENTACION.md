# ANEXO: IMPLEMENTACIÓN PWA (HU + ANGULAR + DEMOS)

> Fuentes principales: `PWA - HU.docx`, `Paybook Reglas de Regocio PWA.docx`, `PWA - ANGULAR TERCERA VUELTA.docx`, `DemoPWA.docx`, `Blueprint de Flujo PWA v2.0.docx`, `PWA - Integración con Odoo.docx`.

---

## 1. Blueprint HU (V6)

- **Visión**: PWA como “Playbook digital” para asesores; integra venta contado, venta a plazo, ahorro programado y crédito colectivo con navegación contextual.
- **Principios**: Asesor siempre presente, motor de reglas contextual (mercado + producto), flexibilidad (recaudo + aportaciones), Odoo como ledger.
- **Épicas**: Seis épicas (núcleo, route-first, motor financiero, expediente, conversión/alertas, producción) que corresponden a HU #01-#25 ya descritas en `CORE_FASE3B_HISTORIAS_USUARIO.md`. Este anexo consolida las referencias al documento original y mapea cada HU a los componentes Angular/Odoo involucrados.

| Épica | HU clave | Componentes PWA | Integraciones |
|-------|---------|-----------------|--------------|
| Núcleo arquitectónico | HU01-HU04 | `Sidebar`, `Cockpit`, `Dashboard` | WebSocket, Odoo (datos cliente) |
| Route-First EdoMéx | HU05-HU06 | `Ecosistemas`, `OnboardingMiembro` | Odoo (contactos ruta), Mifiel |
| Motor financiero | HU07-HU12 | `Configurator`, `Cotizador`, `PlanesHíbridos`, `Conciliación` | Odoo, GNV, Conekta |
| Expediente digital | HU13-HU14 | `DocumentCenter` | Metamap, Odoo Documents |
| Conversión/Alertas | HU15-HU20 | `Ahorro`, `TandaDashboard`, `Alertas`, `EstadoCuenta` | GNV, Conekta, Odoo |
| Producción | HU21-HU25 | `IntegrationsStatus` | GNV API, KIBAN/HASE, Mifiel, Conekta, Odoo |

---

## 2. Paybook de Reglas

Contenido migrado desde `Paybook Reglas de Regocio PWA.docx` (refuerzo de `CORE_FASE3C_REGLAS_NEGOCIO.md`):

- **Aguascalientes**:
  - Venta contado: Vagoneta H6C $799K, GNV opcional, checklist express.
  - Venta a plazo (remanente): paquete $853K, GNV incluido, enganche 60%, financiamiento 40%, plazos 12/24, tasa 25.5%, checklist individual.
- **EdoMéx**:
  - Venta contado: Vagoneta $749K, opcional Paquete Productivo, checklist express.
  - Venta a plazo: Paquete Productivo obligatorio + seguro, enganche 15-20% (15% TANDA), plazos 48/60, tasa 29.9%, pago híbrido, checklist completo.
  - Ahorro/TANDA: Contrato promesa, meta = enganche, método híbrido, conversión automática al alcanzar meta.

Este anexo permite mapear los formularios Angular a las reglas (e.g., validaciones del configurador y checklists dinámicos).

---

## 3. Navegación Angular ("Tercera Vuelta")

Resumen del documento `PWA - ANGULAR TERCERA VUELTA.docx`:

- **Principio Quirúrgico**: Navegabilidad como “Flujo guiado” (GPS estratégico). La PWA no son pantallas aisladas, sino un asistente que muestra la herramienta correcta según contexto.
- **Elementos clave**:
  - Sidebar adaptativo (`Sidebar.tsx` / `SidebarComponent` en Angular): estados colapsado/expandido, badges de acciones pendientes.
  - Alertas contextuales en módulos “Oportunidades” y “Clientes”.
  - Menú inferior en vistas móviles (Pagos / Protección / Mi Unidad / Soporte).
  - Barra de progreso “Puntos RAG” y badges de puntualidad (gamificación).
- **Módulos**:
  - Dashboard operador con tarjetas de saldo, ahorro, mapa eficiencia, CTA Protección Rodando.
  - Flujo de activación Protección Rodando con pantallas encadenadas (alerta → confirmación → plan ajustado).
  - Panel admin RAG (morosidad vs rutas, TIR cartera, % uso protección, alertas HASE).
  - Onboarding digital (SMS, upload documentos, simulador GNV, firma digital + WhatsApp).
  - Marketplace de servicios y módulo de gamificación.
- **Integración**: se enfatiza que cada módulo consulta servicios centralizados (`EcosystemService`, `OdooApiService`, `ProtectionService`) para mantener consistencia.

---

## 4. Demo PWA (`DemoPWA.docx`)

El archivo contiene una PWA en HTML/JS que simula los flujos asesor/cliente:

- **Características**:
  - Router basado en hash para `#/login`, `#/asesor/dashboard`, `#/asesor/lead/{id}`, `#/cliente/{token}`.
  - Creación de leads con datos (nombre, ruta, teléfono) y token de cliente.
  - Simulación de KYC (`startKyc → approved/manual/rejected`), decisión de crédito y estados (aprobado, contrato firmado, pago de enganche) con persistencia localStorage (`cd_leads_v1`).
  - UI con panel lateral, pruebas automáticas (`runTests`) y barra de acciones rápidas.
- **Uso recomendado**: demostraciones rápidas del journey completo (asesor vs cliente) sin depender del backend; útil para training y QA visual.

---

## 5. Integración con Odoo/BFF

`PWA - Integración con Odoo.docx` detalla el `OdooApiService` (Angular) y `EcosystemService`:

- 14 endpoints CRUD para ecosistemas, prospectos, pipeline.
- Modo dual (demo + live) con fallbacks si Odoo no responde.
- Métricas en tiempo real por ecosistema, conversión leads→clientes, asignación dinámica.
- Debe alinearse con `ANEXO_ODOO_SETUP.md` (productos, cuentas, parámetros) y `CORE_FASE4_INTEGRACIONES.md` (autenticación XML-RPC / JSON RPC).

---

## 6. Pendientes / avances

- ✅ `PWA - HU.docx` migrado en `CORE_FASE3B_HISTORIAS_USUARIO.md` (ver sección “Matriz de trazabilidad”).
- ✅ Paybook integrado en `CORE_FASE3C_REGLAS_NEGOCIO.md` con tablas completas.
- ✅ Integración Angular↔Odoo documentada en `CORE_FASE4_INTEGRACIONES.md` (subsección BFF→Odoo, payloads y DTOs).
- ✅ Assets (Visily, Flowise) + DemoPWA enlazados en `CORE_FASE2B_UX_WIREFRAMES.md`.
- 🔄 DemoPWA seguirá recibiendo datos reales cuando el BFF se conecte al entorno productivo; mantener este anexo como bitácora de cambios (último sync 17-dic-2025).

Con este anexo se documenta el material crítico de la carpeta PWA; el foco inmediato pasa a mantener la paridad entre código Angular, BFF y las reglas de negocio.
