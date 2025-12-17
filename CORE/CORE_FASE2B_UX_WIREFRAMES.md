# CORE FASE 2B: UX, WIREFRAMES Y FLOWS

> Fuentes: `Prompts - Wireframes - DeepSeek.docx`, `Visily-Export_26-06-2025_07-31.pdf`, `FlowiseAI_UX_Postventa.png`, archivos PWA (cotizador, protección, CRM).

---

## 🎯 Objetivo

Documentar la experiencia de usuario para asesores, operadores y administradores, incluyendo prompts de diseño, wireframes y conexiones con IA/postventa para asegurar una implementación consistente entre PWA, backend y Odoo.

---

## 1. Componentes Prioritarios

| Prioridad | Vista / Flujo | Descripción | Fuente |
|-----------|---------------|-------------|--------|
| ⚡ Máxima | **Dashboard Operador** | Super-app móvil con saldo pendiente, próximo pago, ahorro GNV, mapa de ruta y activación rápida de Protección Rodando. Menú inferior: Pagos / Protección / Mi Unidad / Soporte. Gamificación con “Puntos RAG”. | Prompts DeepSeek + Visily export |
| 🔥 Crítica | **Activación Protección Rodando** | Secuencia 3 pantallas: alerta push/WhatsApp, confirmación con nuevo plan, gráfico TIR ajustado y mensaje “unidad sigue protegida”. | Prompts DeepSeek |
| ⚠️ Alta | **Panel Admin RAG** | Dashboard desktop con mapa de calor de morosidad por rutas, widgets TIR cartera, % uso protección, alertas HASE y filtros. | Prompts DeepSeek |
| ✨ Alta | **Onboarding Digital** | Flujo 4 pasos (SMS, upload docs INE/Carta ruta, simulador ahorro GNV vs gasolina, firma digital + WhatsApp). | Prompts DeepSeek |
| 💰 Media | **Marketplace Servicios** | “Tienda RAG” con seguros, mantenimientos, recarga GNV. Recomendaciones y promo de tandas. | Prompts DeepSeek |
| 🎮 Media | **Gamificación** | Avatar conductor, progress bar, logros (“Rey GNV”), leaderboard por ruta. | Prompts DeepSeek |

Detalles de cada prompt están en `Prompts - Wireframes - DeepSeek.docx` (ver tabla en el documento) y se usaron para generar los wireframes en Visily.

---

## 2. Wireframes (Visily)

### 2.1 Export `Visily-Export_26-06-2025_07-31.pdf`

Contiene mockups de:
- Dashboard operador (movil)
- Activación Protección Rodando (multimedia)
- Panel admin RAG
- Simulador/Onboarding con comparativa GNV vs gasolina
- Marketplace/Store con upsells
- Gamification leaderboard

**Pendiente:** extraer imágenes clave y anexarlas (conversión a PNG/JPG). Se sugiere subir snapshots a `/wireframes` en el repo.

### 2.2 Flujo IA postventa (`FlowiseAI_UX_Postventa.png`)

Imagen (2111×275 px) con el pipeline del agente RAG (WhatsApp → Twilio → Make → Flowise/OpenAI → Pinecone → respuesta/ticket). Se relaciona con `IDEAS_18_AGENTE_POSTVENTA_RAG.md` (sección de arquitectura). Conviene mover esta imagen a `/assets` y referenciarla en IDEAS/Anexo postventa.

---

## 3. Integración con PWA y Odoo

- Las vistas descritas se corresponden con componentes Angular (`CollectiveCredit`, `Cotizador`, `Document Center`, etc.). Ver `PWA - HU.docx` y `Blueprint Definitivo...` para correspondencia UI↔HU (ej. HU03 Cockpit, HU07 configurador, HU10/11 pagos híbridos).
- Datos maestros (paquetes, cuentas analíticas, rutas) provienen de Odoo (ver `ANEXO_ODOO_SETUP.md`).
- El panel admin RAG consolida métricas del core bancario (FASE9) y HASE/Voice Pattern (LOGICA Sección 2/6).
- Onboarding y upload documental se conectan con Metamap/Mifiel/Conekta (FASE4 integraciones).

---

## 4. Roadmap UX

1. **Estandarizar prompts** (DeepSeek) → replicarlos en Figma/Visily con branding final.
2. **Capturar assets**: export PNG/JPG para cada vista y alojar en `/wireframes`.
3. **Crear prototipos interactivos** (Visily/Figma) para capacitación asesores.
4. **Sincronizar con PWA**: verificar que componentes Angular reflejen los flujos aquí descritos (huellas UI ↔ código). Documentar diferencias en `PWA - HU.docx` y migrarlas a este anexo.
5. **Conectar a IA**: Ensure flow diagrams (Flowise) estén linkeados a IDEAS_18 y `ANEXO_POSTVENTA_HIGER.md`.
6. **Actualizar auditoría**: marcar gap “Wireframes/Flujos UX” como en proceso a medida que se suban los assets.

---

## 5. Pendientes

- Migrar los wireframes (PDF/PNG) al repositorio (pos. `/assets/wireframes/`).
- Extraer contenido de `PWA - Integración con Odoo.docx`, `PWA - ANGULAR TERCERA VUELTA.docx`, `Paybook Reglas...` y unificarlo con HU/Reglas.
- Documentar específicamente el “Panel Admin RAG” y “Dashboard operador” con datos reales (ej. valores HASE/TIR/Protección Rodando) para que el equipo de BI pueda replicarlos.

Con este anexo se cubre el gap de wireframes/UX identificado en la auditoría. Falta completar los assets visuales y alinear el código Angular con el diseño final.
