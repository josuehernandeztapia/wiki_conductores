# ANEXO: POSTVENTA HIGER – REFACCIONES Y SOPORTE

> Fuentes: `POSTVENTA HIGER - REFACCIONES.docx`, `Higer Spare Parts -1.xlsx`, `part_equivalences_complete.sql/.xlsx`, `higer_nationalization_ssot.xlsx`, `Poliza Garantía - HIGER.docx`.

---

## 1. Historias de Usuario

1. **HU1 – Catálogo nacionalizado**: Admin quiere catálogo completo de refacciones Higer H6C con número original, equivalencia Toyota y proveedores mexicanos.
2. **HU2 – Buscador interactivo**: Usuario necesita buscar por nombre/código y obtener equivalencias, proveedores y observaciones al instante.
3. **HU3 – Gestión de garantías**: Agente debe identificar si la pieza está en garantía y, si no, ofrecer opciones de compra con enlaces/contactos.
4. **HU4 – Stock nacional**: Responsable de inventario carga precios y existencias disponibles en México para alimentar la PWA.
5. **HU5 – Integración RAG/IA**: Catálogo e inventario deben quedar accesibles vía API para que el asistente de postventa (WhatsApp/Make) dé respuestas unificadas.
6. **HU6 – Guía de búsqueda e-commerce**: Usuarios obtienen tips para rastrear piezas en Mercado Libre, Amazon, etc., usando códigos equivalentes.
7. **HU7 – Actualización continua**: Admin puede añadir nuevas equivalencias y recomendaciones prácticas basadas en experiencia de taller.
8. **HU8 – Manual interactivo**: La guía de nacionalización debe ser visual, con infografías, glosario y enlaces directos.

---

## 2. Catálogo de Refacciones Nacionalizadas

Tabla base (`Higer Spare Parts -1.xlsx`) con >150 ítems; ejemplo:

| Nombre | Código Higer | Sistema | Vendible | Tipo |
|--------|--------------|---------|----------|------|
| Perno de montaje de motor | 10Z15-00811 | Sistema de Potencia | Sí | Bienes |
| Abrazadera filtro de aire | 11FC1-09012 | Sistema de Potencia | Sí | Bienes |
| Sello aceite diferencial | 24FC1-02501-C | Ejes/Suspensión | Sí | Bienes |
| Balero piñón | 24FC1-02502-C | Ejes/Suspensión | Sí | Bienes |
| Válvula expansión A/C | 81Z15-07111-B | Climatización | Sí | Bienes |

Cada producto incluye categoría, descripción y bandera “se puede vender” para integrarlo en Odoo PWA.

---

## 3. Equivalencias y Proveedores Nacionales

`part_equivalences_complete.xlsx` + `.sql` mapean cada referencia Higer a proveedores locales (Bosch, Mann, WIX). Ejemplos:

| Ref. Higer | Proveedor | Código proveedor | Descripción |
|------------|-----------|------------------|-------------|
| 90915-YZZE1 (filtro aceite) | Bosch | 0986AF0273 | Equivalente 0986AF0273 |
| 90915-YZZE1 | Fram | PH4967 | Repuesto Fram PH4967 |
| 90915-YZZE1 | Mann | W68/3 | Filtro Mann W68/3 |
| 17801-75010 (filtro aire) | Bosch | 1457433795 | Equivalente Bosch |
| 17801-75010 | Mann | C14177 | Equivalente Mann |

Estos scripts pueden importarse a la tabla `part_equivalences` (ver `CORE_FASE8_NEON_DATABASE.md`, sección catálogos) para alimentar búsquedas.

---

## 4. Guía de Nacionalización y Telemetría

`higer_nationalization_ssot.xlsx` documenta cada sistema (motor, frenos, carrocería, eléctrico) con fuentes de referencia (Toyota Hiace 2.7, catálogos Bosch/Mann, etc.) y estrategias de búsqueda:

- **Sistema motor**: usar equivalencias Toyota y catálogos Bosch/Mann; validar con Plenty.Parts.
- **Sistema frenos**: referencia `S23FC-55024` y tiendas locales.
- **Climatización/eléctrico**: rines, alternadores, relevadores listados con proveedores chinos y equivalentes locales.
- **Tips e-commerce**: keywords sugeridas para Mercado Libre, Amazon y AutoZone.

Esto alimenta la HU6/HU8 y se integra con el agente RAG (IDEAS_18) para sugerencias automáticas.

---

## 5. Flujos Operativos

1. **Búsqueda interna**: La PWA consulta la tabla de refacciones y equivalencias para mostrar stock, equivalencias y proveedores.
2. **Garantías**: `Poliza Garantía - HIGER.docx` define cobertura; si una pieza está en garantía, se genera ticket y se evita compra. Si no, se sugieren proveedores nacionales.
3. **Integración RAG**: API `/spareparts` + `/stock` complementan `/query` del asistente IA (IDEAS_18), permitiendo respuestas mixtas (diagnóstico + refacción).
4. **Telemetría → mantenimiento**: Se propone integrar lecturas OBD/GPS para disparar compras de refacciones según uso real (ver sección final del documento de refacciones).

---

## 6. Integraciones y Tecnología Recomendada

- **Base de datos relacional** (PostgreSQL) para refacciones, equivalencias y stock (`spare_parts`, `part_equivalences` en NEON).
- **API FastAPI** con endpoints:
  - `GET /spareparts?query=` (búsqueda por nombre/código).
  - `GET /spareparts/{id}/equivalences`.
  - `GET /stock/{warehouse}`.
  - `GET /guides/nationalization`.
- **Pinecone/OpenAI** para integrar contenido técnico en el agente RAG.
- **Make.com/Twilio** para flujos WhatsApp (consultas de refacciones, notificaciones de stock) conectados a la API.
- **Odoo/Airtable**: opcional para registrar stock y solicitudes (ver roadmap migración en IDEAS_18).

---

## 7. Roadmap Propuesto

1. **Fase 0 – Catálogo local**: PWA consume JSON local con las tablas anteriores; UI permite búsqueda, equivalencias y proveedores.
2. **Fase 1 – API en FastAPI**: Exponer `/spareparts` y `/stock` reales, manteniendo fallback local.
3. **Fase 2 – Integración Odoo**: Sincronizar `spare_parts` con Odoo Inventario (modulo de refacciones) y estados de garantía.
4. **Fase 3 – RAG**: Incorporar catálogos en Pinecone/Flowise para que el agente IA responda consultas (IDEAS_18).
5. **Fase 4 – Telemetría**: Conectar lecturas GPS/OBD para mantenimientos predictivos (alertas automáticas + sugerencia de refacciones).

Con este anexo se cubre el gap identificado en la auditoría (“POSTVENTA HIGER”). El siguiente paso es integrar estas tablas en NEON/Odoo y conectar la PWA/IA siguiendo el roadmap.
