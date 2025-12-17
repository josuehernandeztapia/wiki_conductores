# ANEXO: CONFIGURACIÓN COMPLETA ODOO + ECOSISTEMA CONDUCTORES

> Fuentes: Documentación interna de agosto–diciembre 2025 (`🚀 DEEP DIVE QUIRÚRGICO- VENTA CONTADO + TANDA COLECTIVA.docx`, `Odoo API Integration Complete.docx`, `Avance Setup Odoo - 15 de Agosto 2025.docx`, `⏺ 🏗️ CONFIGURACIÓN COMPLETA- ODOO + ECOSISTEMA CONDUCTORES.docx`, `Catalogo de Cuentas.xlsx`).

---

## 1. Estado Actual de la Instancia

- **Versión:** Odoo 16/17 Enterprise con localización México y 74 apps disponibles.
- **Módulos core activos:** CRM, Ventas, Contabilidad (CFDI 4.0), Inventario, Proyecto, Empleados, Gastos, Documentos, Mantenimiento y Studio.
- **Datos fiscales configurados:**
  - Razón Social `Conductores del Mundo SAPI de CV`.
  - RFC `CMU201119DD6`.
  - PAC: SW sapient–SmarterWEB (certificados .cer/.key cargados).
  - Régimen Fiscal: General de Ley Personas Morales.
- **Usuarios:** 2 activos + invitaciones; roles diferenciados (Vendedor AGS, Vendedor EdoMéx, Operaciones, Finanzas).
- **Automatizaciones habilitadas:** enriquecimiento de leads, puntuación predictiva, firma electrónica, confirmaciones SMS, geolocalización Mapbox, Google Places, código de barras.

---

## 2. Catálogo de Productos por Mercado

Los scripts XML/Studio crean categorías y productos homologueados para la PWA:

| ID | Producto / Componente | Mercado | Precio Lista | Notas |
|----|-----------------------|---------|-------------|-------|
| `VAG-H6C-19-AGS` | Vagoneta H6C 19p | Aguascalientes | $799,000 | Base para contado; conversión GNV opcional. |
| `CONV-GNV` | Conversión GNV | AGS/EdoMéx | $54,000 | Obligatoria en financiamiento AGS y dentro del Paquete Productivo EdoMéx. |
| `VAG-H6C-V-EDOMEX` | Vagoneta H6C Ventanas | EdoMéx | $749,000 | Debe venderse con Paquete Productivo completo. |
| `PAQ-TEC` | Paquete Tecnológico | EdoMéx | $12,000 | Marcado como componente obligatorio en Paquete Productivo. |
| `BANCAS-ADD` | Bancas adicionales | EdoMéx | $22,000 | Complemento requerido. |
| `SEG-ANUAL` | Seguro vehicular anual | Todos | $36,700 por año | Campo `x_multiplied_by_term` para multiplicar por plazo (48/60 m). |

> Los templates incluyen metadatos (`x_market`, `x_is_component`, `x_required_for_financing`) para que la API PWA pueda filtrar y construir cotizaciones dinámicas.

---

## 3. Catálogo de Cuentas (Resumen)

`Catalogo de Cuentas.xlsx` define el plan contable NIIF + MX. Fragmento principal:

| Código | Nombre | Tipo | Reconciliable |
|--------|--------|------|---------------|
| 1111 | Caja | Bank and Cash | No |
| 1112 | Cuentas Bancarias | Bank and Cash | Sí |
| 1121 | CxC – Créditos Operadores | Receivable | Sí |
| 1131 | Inventario de Vagonetas | Current Assets | No |
| 1211 | Flota de Vehículos | Fixed Assets | No |
| 2110 | Proveedores | Payable | Sí |
| 2130 | Pasivos por Contrato (NIIF 15) | Current Liabilities | No |
| 2210 | Deuda Financiera Largo Plazo | Non-current Liabilities | No |
| 3110 | Capital Social Pagado | Equity | No |
| 4110 | Ingresos por Venta de Unidades | Income | No |
| 4120 | Ingresos por Financiamiento | Income | No |
| 5110 | Costo de Ventas Vagonetas | Cost of Goods Sold | No |
| 5120 | Costo Financiero (NIIF 9) | Cost of Revenue | No |
| 6110 | Gasto Operativo Comercial | Expense | No |
| 7110 | Reservas y Provisiones (NIIF 9) | Expense | No |

Estos códigos se utilizan en los journals de core banking (Banco NEON 101, Ingreso 405, Proveedores 201) y en los reportes financieros.

---

## 4. Journals y Core Banking

1. **Journals bancarios**: SPEI ventas contado (`code: SPEI`, cuenta 102-01), cuentas virtuales (`code: CVIR`, cuenta 105-01), tandas y dispersión (cuentas 101/201).
2. **Módulo `odoo_corebanking`**: modelos `corebanking.virtual_account`, `corebanking.transaction`, `corebanking.reconciliation` para enlazar NEON ↔ Odoo.
3. **Flujo 14 pasos** (FASE9) mapea pagos Conekta → Airtable → validaciones → asiento Odoo → conciliación → estados de cuenta → dispersión via NEON. Los scripts del deep dive muestran cómo registrar entradas/salidas y adjuntar comprobantes (`account.move`, `account.payment`).

---

## 5. CRM Pipeline y Document Center (Integración PWA)

- **OdooApiService** (Angular) expone 14 endpoints CRUD para ecosistemas, rutas y prospectos, sincronizando `res.partner`, `crm.lead` y métricas del pipeline.
- **CRM Pipeline**: cuatro etapas (Nuevos, Contactados, Cualificados, Convertidos) con scoring, automatizaciones (WhatsApp/Email), panel de acciones y métricas en vivo.
- **Document Center**: upload drag & drop con OCR, clasificación por tipo, validaciones y estado del expediente. Se almacena en `documents.document` y se enlaza al checklist del modelo personalizado (Onboarding). Incluye workflows de aprobación y alertas.
- **BI y Dashboard**: Vistas Kanban, métricas por origen/ecosistema y reports QWeb listos para exportar.

Estas capacidades están activas en la PWA (rutas `/crm-pipeline`, `Document Center`) y consumen los endpoints reales de Odoo.

---

## 6. Flujos Venta Contado + Tanda

El “Deep Dive Quirúrgico” define scripts y acciones clave:

1. **Venta Contado**: PWA → Cotización → Pago SPEI/Conekta → `sale.order.action_confirm()` → `account.payment` → factura CFDI → entrega del vehículo.
2. **Tanda Colectiva**:
   - Modelos `conductores.tanda`, `conductores.tanda.member`, `conductores.tanda.cycle` (Studio/custom).
   - Procesos `process_payment(member_id, amount, method)` para asignar pagos a deuda/ahorro.
   - Cuenta analítica maestra por grupo y líneas por miembro.
   - Integración con Mifiel (`send_contract_for_signature`) para contratos colectivos.
3. **Scripts incluidos**: creación de productos, journals, server actions, botones (“Imprimir estado de cuenta”, webhooks, notificaciones).

---

## 7. Parámetros del Sistema e Integraciones

Configurar en `Settings > Technical > Parameters > System Parameters`:

| Clave | Ejemplo |
|-------|---------|
| `conekta.api_key`, `conekta.webhook_secret` | Credenciales live |
| `mifiel.app_id`, `mifiel.secret_key` | Firma electrónica |
| `metamap.client_id`, `metamap.flow_id_mexico` | KYC México |
| `whatsapp.access_token`, `whatsapp.phone_number_id` | Meta Business |
| `make.webhook.*` | Webhooks para eventos (lead welcome, payment, hitos TANDA) |
| `airtable.api_key`, `airtable.base_id` | Staging documental |
| `conductores.pwa_url`, `conductores.erp_url` | URLs oficiales |

Además de los parámetros, la receta incluye plantillas de mensajes, templates WhatsApp y escenarios Make (ruteo de pagos, milestones de TANDA, confirmaciones a asesores).

---

## 8. Checklist de Implementación (8 días)

| Fase | Duración | Actividades |
|------|----------|-------------|
| 1. Setup inicial | 1 día | Instalar Odoo MX, parametrizar empresa/PAC, crear usuarios/roles, cargar parámetros del sistema. |
| 2. Productos y flujos | 1 día | Ejecutar scripts XML, configurar journals y cuentas virtuales, crear ecosistemas demo, probar PWA ↔ Odoo. |
| 3. Integraciones | 2 días | Webhooks Conekta, pruebas SPEI/efectivo/tarjeta, Mifiel, Metamap, WhatsApp, scenarii Make, Airtable. |
| 4. Tandas colectivas | 2 días | Modelos personalizados, lógica ahorro/pago, automatización de entregas, reportes financieros. |
| 5. Core bancario | 1 día | Cuentas virtuales, conciliación automática, estados PDF, SPEI salientes. |
| 6. Testing & Go Live | 1 día | Pruebas end-to-end, stress, backup, documentación, entrenamiento y despliegue. |

> La auditoría marcaba “Odoo Setup Completo” como gap; este anexo consolida los pasos, scripts y configuraciones necesarias para cubrirlo. Falta ejecutar las tareas operativas (checklist FASE9) para considerarlo 100% implementado.

---

## 9. Recomendaciones Inmediatas

1. Centralizar el checklist documental en los modelos Studio y vincularlo a `documents.document` (evitar duplicados por flujo).
2. Activar automatizaciones básicas (server actions) para creación de cuentas analíticas, avances de etapa y alertas de inactividad.
3. Definir permisos por rol/mercado y filtros de registro para proteger datos sensibles.
4. Crear registros demo de cada flujo (contado, remanente, ahorro, tanda) para capacitación y testing.
5. Preparar exportables QWeb (estado de cuenta incluido) y vistas de movimientos analíticos para auditorías.

Con esta guía, cualquier equipo puede reconstruir o auditar la instancia Odoo sin depender de documentos externos.
