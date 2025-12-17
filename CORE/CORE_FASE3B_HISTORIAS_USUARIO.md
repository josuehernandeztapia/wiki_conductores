# FASE 3B: HISTORIAS DE USUARIO (USER STORIES)

**Blueprint Maestro v6.0** - Plataforma de Operaciones "Conductores del Mundo"

---

## 📋 VISIÓN GENERAL

Este documento es la fuente única de verdad para la reconstrucción de la plataforma PWA. El objetivo es crear una **PWA de clase empresarial** que funcione como el **"Playbook Digital"** para los asesores.

> Configuraciones completas en Odoo (productos, cuentas analíticas, journals, parámetros) se documentan en `ANEXO_ODOO_SETUP.md`.

La plataforma integrará todos los flujos de negocio:
- ✅ Venta de Contado
- ✅ Ahorro Programado
- ✅ Venta a Plazo
- ✅ Crédito Colectivo (TANDA)

Se adaptará dinámicamente a las reglas de cada mercado, bajo la filosofía **"High Tech, High Touch"**.

---

## 🎯 PRINCIPIOS NO NEGOCIABLES

### 1. Asesor Siempre Presente
La PWA es la herramienta que el asesor usa **con** el cliente. Cada acción y comunicación está diseñada para ser iniciada o supervisada por el asesor.

### 2. Motor de Reglas Contextual
La PWA no es un formulario lineal. Es un **asistente inteligente** que se adapta al:
- Tipo de Venta (Contado vs. Financiado)
- Mercado (Aguascalientes vs. Estado de México)

### 3. Flexibilidad Total
El sistema debe manejar de forma nativa los modelos de pago y ahorro híbridos:
- Recaudo (API de GNV)
- Aportaciones Voluntarias (Conekta)

### 4. Odoo como Ledger
Odoo es la fuente de verdad contable. Cada transacción financiera debe reflejarse allí de forma auditable.

---

## 📊 ESTRUCTURA: 6 ÉPICAS, 25 HISTORIAS DE USUARIO

| Épica | Historias | Objetivo |
|-------|-----------|----------|
| **Épica 1: Núcleo Arquitectónico** | HU #01-#04 | Base técnica y cockpit del asesor |
| **Épica 2: Flujo Route-First** | HU #05-#06 | Colateral social (EdoMex) |
| **Épica 3: Motor Financiero** | HU #07-#12 | Cotizador y pagos híbridos |
| **Épica 4: Expediente Digital** | HU #13-#14 | Gestión documental |
| **Épica 5: Conversión y Alertas** | HU #15-#20 | Flujos colectivos y notificaciones |
| **Épica 6: Puesta en Producción** | HU #21-#25 | Integración de APIs reales |

---

## 🏛️ ÉPICA 1: EL NÚCLEO ARQUITECTÓNICO Y EL COCKPIT DEL ASESOR

**Objetivo:** Establecer la base tecnológica y la interfaz principal desde donde el asesor orquestará toda la experiencia del cliente.

### HU #01: Andamiaje del Monorepo y Servicios Core

**Como** desarrollador líder
**Quiero** establecer el monorepo con workspaces para backend (NestJS) y frontend (Angular), incluyendo los servicios transversales de WebSocket, autenticación (roles: asesor/cliente) y un SimulationService para desarrollo
**Para que** tengamos una base de código limpia, modular y escalable desde el primer commit

**Integraciones:** N/A (Setup inicial)

---

### HU #02: El Árbol de Decisión Maestro

**Como** asesor
**Quiero** que al presionar `+ Nueva Oportunidad`, la PWA me guíe a través de un árbol de decisión para configurar la oferta correcta
**Para que** pueda iniciar cualquier flujo de negocio de forma intuitiva y sin errores

**Criterios de Aceptación:**
- ✅ La PWA presenta la primera bifurcación: **De Contado** vs. **Con Apoyo Financiero**
- ✅ Si se elige Con Apoyo Financiero, la PWA presenta la segunda bifurcación: **Mercado** (Aguascalientes vs. Estado de México)
- ✅ La selección en cada paso filtra las opciones y requisitos en las pantallas subsecuentes

**Diagrama:**
```
+ Nueva Oportunidad
  ├─ De Contado
  │   └─ Checklist Express (INE, Comprobante, CSF)
  └─ Con Apoyo Financiero
      ├─ Aguascalientes
      │   └─ Checklist Individual (INE, Comprobante, Tarjeta Circulación, Concesión, CSF)
      └─ Estado de México
          └─ Checklist Completo + Colateral Social (Factura, Carta Aval Ruta, Convenio Dación)
```

---

### HU #03: El Cockpit de Cliente 360°

**Como** asesor
**Quiero** una vista unificada para cada cliente que consolide toda su información relevante en una sola pantalla
**Para que** pueda entender su estatus de un vistazo y saber cuál es la próxima acción recomendada

**Criterios de Aceptación:**
Diseñar una vista maestra **"Expediente Activo"** que contenga:
- ✅ Header con datos del cliente y Estado Global
- ✅ Módulo Financiero Central (barra de progreso de ahorro o estado del pago mensual)
- ✅ Checklist de Expediente dinámico
- ✅ Log de Eventos en tiempo real
- ✅ Botón de **"Acción Recomendada"** contextual

**Integraciones:**
- Odoo (para datos de cliente y estado)
- WebSocket (para actualizaciones en vivo)

**Wireframe:**
```
┌────────────────────────────────────────┐
│ [Foto] Juan Pérez                      │
│ Score HASE: 87 (AA) | Estado: ACTIVO  │
├────────────────────────────────────────┤
│ MÓDULO FINANCIERO                      │
│ Ahorro: $45,000 / $60,000 (75%)       │
│ [████████░░] Meta: $60,000             │
├────────────────────────────────────────┤
│ CHECKLIST EXPEDIENTE (8/10)           │
│ ✅ INE | ✅ Comprobante | ⏳ CSF       │
├────────────────────────────────────────┤
│ LOG EVENTOS                            │
│ • 10:30 - Pago recibido $5,000        │
│ • 09:15 - Documento CSF subido        │
├────────────────────────────────────────┤
│ [🔔 ACCIÓN: Solicitar CSF faltante]   │
└────────────────────────────────────────┘
```

---

### HU #04: Dashboard Principal Orientado a la Acción

**Como** asesor
**Quiero** un dashboard principal que agrupe a mis clientes por la naturaleza de la tarea a realizar, en lugar de una lista genérica
**Para que** pueda priorizar mi día y enfocarme en los clientes que requieren mi atención inmediata

**Criterios de Aceptación:**
- ✅ El dashboard tendrá secciones como:
  - **"Bandeja de Entrada (Nuevos Prospectos)"**
  - **"Planes de Ahorro Activos"**
  - **"Ventas a Plazo por Conciliar"**
- ✅ Cada cliente se representará con una **"Tarjeta Inteligente"** que resuma su estado y ofrezca acciones rápidas contextuales

**Wireframe:**
```
DASHBOARD ASESOR
┌──────────────────────────────────────┐
│ 📥 BANDEJA DE ENTRADA (3)            │
│ ┌────────────────────────────────┐   │
│ │ María López | NUEVO              │   │
│ │ Ahorro $0/$60K | ⚠️ Falta INE    │   │
│ │ [Ver Expediente] [Solicitar Doc] │   │
│ └────────────────────────────────┘   │
├──────────────────────────────────────┤
│ 💰 PLANES DE AHORRO ACTIVOS (12)     │
│ ┌────────────────────────────────┐   │
│ │ Juan Pérez | 75% Meta Alcanzada  │   │
│ │ $45K/$60K | ✅ Expediente OK     │   │
│ │ [Ver Dashboard] [Simular Plazo]  │   │
│ └────────────────────────────────┘   │
├──────────────────────────────────────┤
│ 📊 VENTAS A PLAZO (8)                │
│ ┌────────────────────────────────┐   │
│ │ Pedro Ramírez | Pago Mes 12/36   │   │
│ │ Al día | Próximo pago: 15-Oct    │   │
│ │ [Ver Estado Cuenta] [Contactar]  │   │
│ └────────────────────────────────┘   │
└──────────────────────────────────────┘
```

---

## 🌳 ÉPICA 2: EL FLUJO DE ECOSISTEMA "ROUTE-FIRST" (ESTADO DE MÉXICO)

**Objetivo:** Implementar el modelo de negocio basado en el colateral social, donde la relación se establece primero con la Ruta y luego con sus miembros.

### HU #05: Gestión de Ecosistemas (Rutas)

**Como** asesor del mercado Estado de México
**Quiero** una sección en la PWA para dar de alta, verificar y gestionar "Ecosistemas de Ruta"
**Para que** pueda establecer la base del colateral social firmando un Convenio Marco de Colaboración antes de procesar a sus miembros

**Criterios de Aceptación:**
- ✅ La PWA tendrá una sección **"Mis Ecosistemas"** con un botón `+ Nuevo Ecosistema`
- ✅ Se debe poder completar un expediente para la ruta (Acta Constitutiva, Poder del Representante, etc.)
- ✅ El sistema debe generar y enviar el **Convenio Marco** para firma con Mifiel

**Integraciones:**
- Odoo (para crear un nuevo tipo de Contacto "Ruta")
- Mifiel (para firma digital)

**Flujo:**
```
1. Asesor → + Nuevo Ecosistema
2. Captura datos de Ruta (Nombre, Representante, Línea)
3. Sube documentos (Acta Constitutiva, Poder, etc.)
4. Sistema genera Convenio Marco → envía a Mifiel
5. Representante firma → Ecosistema ACTIVO
6. Ahora se pueden agregar miembros vinculados a esta Ruta
```

---

### HU #06: Onboarding de Miembros Vinculado a un Ecosistema

**Como** asesor del mercado Estado de México
**Quiero** que al iniciar un Apoyo Financiero, el sistema me pida vincular al cliente con un Ecosistema de Ruta ya verificado
**Para que** la PWA solicite automáticamente el expediente completo, incluyendo Carta Aval de Ruta y Convenio de Dación en Pago

**Criterios de Aceptación:**
- ✅ La PWA mostrará una lista de Ecosistemas registrados para seleccionar
- ✅ El checklist de documentos incluirá los campos para las garantías del colateral social:
  - Factura de unidad actual
  - Carta Aval de Ruta
  - Convenio de Dación en Pago
- ✅ El backend validará que la ruta seleccionada tenga un Convenio Marco activo

**Integraciones:**
- Odoo (para vincular el contacto del miembro con el contacto de la Ruta)

---

## 💸 ÉPICA 3: EL MOTOR FINANCIERO FLEXIBLE Y CONTEXTUAL

**Objetivo:** Construir el cotizador inteligente y los flujos de pago que materializan la oferta de flexibilidad total.

### HU #07: Configuración de Productos por Mercado en Odoo

**Como** administrador de negocio
**Quiero** poder configurar en Odoo "Paquetes de Producto" por mercado, definiendo todos los componentes, precios y reglas de financiamiento
**Para que** la PWA del asesor pueda consumir esta configuración y construir el cotizador dinámicamente sin tener la lógica de negocio en el frontend

**Integraciones:** Odoo (ver `ANEXO_ODOO_SETUP.md` para scripts y componentes)

**Ejemplo de Configuración:**
```yaml
Mercado: Aguascalientes - Contado
Productos:
  - Vagoneta 19p: $350,000 MXN
  - GNV (Opcional): $45,000 MXN
  - Paquete Productivo (Opcional): $30,000 MXN

Mercado: Estado de México - Financiado
Productos:
  - Vagoneta 19p: $350,000 MXN
  - GNV (Obligatorio): $45,000 MXN
  - Paquete Productivo (Obligatorio): $30,000 MXN
Reglas:
  - Enganche mínimo: 20%
  - Tasa: 16% anual
  - Plazo máximo: 48 meses
```

---

### HU #08: Configurador de Paquetes Dinámicos en PWA

**Como** asesor
**Quiero** que la PWA me presente un configurador de paquetes que se adapte al Tipo de Venta y Mercado seleccionados
**Para que** pueda armar la oferta correcta para cada cliente, ya sea de contado o financiada

**Criterios de Aceptación:**
- ✅ El configurador debe mostrar los productos y opciones correctas para cada escenario:
  - **Aguascalientes - Contado:** Vagoneta 19p con GNV opcional
  - **EdoMex - Financiado:** Paquete Productivo obligatorio
- ✅ El Valor Total debe recalcularse en tiempo real

**Integraciones:**
- Odoo (para obtener los catálogos de productos y precios)

**Wireframe:**
```
CONFIGURADOR DE PAQUETES
┌────────────────────────────────────┐
│ Mercado: Aguascalientes - Contado │
├────────────────────────────────────┤
│ ✅ Vagoneta 19p      $350,000 MXN  │
│ ☐ GNV (Opcional)      $45,000 MXN  │
│ ☐ Paq. Productivo     $30,000 MXN  │
├────────────────────────────────────┤
│ VALOR TOTAL:          $350,000 MXN │
│ [Generar Cotización]               │
└────────────────────────────────────┘
```

---

### HU #09: Cotizador y Motor de Amortización Contextual

**Como** asesor
**Quiero** un cotizador que aplique las reglas financieras correctas (tasas, plazos, enganches) y genere tablas de amortización detalladas
**Para que** pueda modelar escenarios financieros con el cliente y darle total transparencia

**Criterios de Aceptación:**
- ✅ El cotizador debe cargar las tasas, plazos y enganches mínimos según el Mercado y Tipo de Cliente (Individual/Colectivo)
- ✅ Debe calcular el Pago Mensual usando fórmula French:
  ```
  PMT = P * [r(1+r)^n] / [(1+r)^n - 1]
  ```
- ✅ Debe generar una tabla de amortización completa (ver LOGICA_MATEMATICA.md Sección 3)
- ✅ Debe permitir la descarga de la cotización y la tabla en PDF

**Integraciones:**
- Odoo (para guardar la cotización final en la oportunidad)

**Ejemplo de Output:**
```
COTIZACIÓN GENERADA
Cliente: Juan Pérez
Mercado: Aguascalientes - Financiado
Valor Vehículo: $350,000 MXN
Enganche: $70,000 MXN (20%)
Monto Financiado: $280,000 MXN
Tasa: 16% anual
Plazo: 36 meses
Pago Mensual: $9,876 MXN

[Descargar PDF] [Compartir por WhatsApp]
```

---

### HU #10: Configuración de Planes de Pago y Ahorro Híbridos

**Como** asesor
**Quiero** poder configurar planes de ahorro y pago que combinen Recaudación y Aportaciones Voluntarias
**Para que** pueda ofrecer la máxima flexibilidad al cliente

**Criterios de Aceptación:**
- ✅ La PWA debe presentar los checkboxes para activar ambos métodos de pago/ahorro:
  - ☑️ Recaudación (API de GNV)
  - ☑️ Aportaciones Voluntarias (Conekta)
- ✅ Si se activa la recaudación, se deben poder registrar:
  - Placas del vehículo
  - Sobreprecio GNV (ej. $0.50 MXN/kg)
- ✅ Esta configuración debe guardarse en Odoo y reflejarse en el contrato

**Integraciones:**
- API de GNV (para activar la regla de recaudo)

**Flujo:**
```
1. Asesor configura plan de pago/ahorro
2. Activa checkboxes: ☑️ Recaudación + ☑️ Aportaciones
3. Registra placas: ABC-123-XYZ
4. Define sobreprecio: $0.50 MXN/kg
5. Sistema guarda en Odoo
6. Genera contrato con ambos métodos
```

---

### HU #11: Conciliación de Pagos Híbridos

**Como** asesor
**Quiero** que el dashboard del cliente concilie automáticamente los pagos provenientes de la API de GNV y de Conekta
**Para que** pueda ver un Saldo Pendiente o Saldo de Ahorro preciso y en tiempo real

**Criterios de Aceptación:**
- ✅ El backend debe tener un proceso (webhook/cron job) para obtener los datos de la API de GNV
- ✅ El backend debe procesar los webhooks de Conekta
- ✅ Ambos flujos deben registrar las transacciones en la **Cuenta Analítica del cliente** en Odoo

**Integraciones:**
- API de GNV
- Conekta
- Odoo (cuentas analíticas; referencia en anexo)

**Ejemplo de Conciliación:**
```
DASHBOARD CLIENTE: Juan Pérez
┌────────────────────────────────────┐
│ PLAN DE AHORRO: $45,000 / $60,000  │
├────────────────────────────────────┤
│ TRANSACCIONES (Últimos 7 días)     │
│ • 12-Oct | Recaudo GNV    $1,200   │
│ • 10-Oct | Conekta SPEI   $5,000   │
│ • 08-Oct | Recaudo GNV    $1,350   │
│ • 05-Oct | Conekta Tarjeta $2,500  │
├────────────────────────────────────┤
│ TOTAL ACUMULADO: $10,050            │
│ Meta restante: $4,950 (83% cumplida)│
└────────────────────────────────────┘
```

---

### HU #12: Lógica de Opciones de Pago por Monto

**Como** sistema
**Quiero** ofrecer métodos de pago seguros y apropiados según el monto de la transacción
**Para que** cumplamos con las regulaciones y ofrezcamos la mejor opción al cliente

**Criterios de Aceptación:**
- ✅ Si el monto **≤ $20,000 MXN**, se muestran las opciones de Conekta:
  - Tarjeta de Crédito/Débito
  - OXXO Pay
- ✅ Si el monto **> $20,000 MXN**, la opción principal debe ser:
  - SPEI (Transferencia)

**Integraciones:** Conekta

**Diagrama:**
```
Monto a Pagar
├─ ≤ $20,000 MXN
│   ├─ Tarjeta Crédito/Débito
│   └─ OXXO Pay
└─ > $20,000 MXN
    └─ SPEI (Transferencia)
```

---

## 📝 ÉPICA 4: EL EXPEDIENTE DIGITAL Y LA GESTIÓN DOCUMENTAL

**Objetivo:** Asegurar que la PWA capture la documentación correcta para cada flujo y permita una gestión de archivos flexible pero segura.

### HU #13: Checklist de Documentos Dinámico

**Como** sistema
**Quiero** mostrar al asesor un checklist de documentos que se adapte automáticamente al Tipo de Venta y Mercado
**Para que** siempre solicitemos el expediente correcto

**Criterios de Aceptación:**
- ✅ **Checklist Express** para Contado:
  - INE
  - Comprobante de Domicilio
  - Constancia de Situación Fiscal (CSF)
- ✅ **Checklist Individual** para Aguascalientes - Financiado:
  - INE
  - Comprobante de domicilio
  - Tarjeta de circulación
  - Concesión
  - Constancia de situación fiscal
- ✅ **Checklist Completo** para EdoMex - Financiado:
  - Todos los del Individual **MÁS**:
    - Factura de unidad actual
    - Carta Aval de Ruta
    - Convenio de Dación en Pago

**Tabla:**
| Tipo Venta | Mercado | Documentos Requeridos |
|------------|---------|----------------------|
| Contado | Universal | INE, Comprobante, CSF |
| Financiado | Aguascalientes | INE, Comprobante, Tarjeta Circulación, Concesión, CSF |
| Financiado | Estado de México | INE, Comprobante, Tarjeta, Concesión, CSF, Factura, Carta Aval Ruta, Convenio Dación |

---

### HU #14: Carga de Archivos Flexible (Imagen y PDF)

**Como** asesor
**Quiero** poder subir documentos tomándoles una foto con mi tablet o seleccionando un archivo PDF
**Para que** el proceso de digitalización en campo sea lo más rápido posible

**Criterios de Aceptación:**
- ✅ El componente de carga de archivos debe aceptar:
  - JPG
  - PNG
  - PDF
- ✅ Para documentos formales (Contratos, Actas), la UI debe mostrar un mensaje recomendando el uso de PDF
- ✅ La PWA debe comprimir las imágenes antes de subirlas (reducir tamaño para optimizar bandwidth)

**Flujo:**
```
1. Asesor selecciona documento "INE"
2. Opciones: [📷 Tomar Foto] [📁 Subir Archivo]
3. Si foto → captura con cámara tablet → comprime → sube
4. Si archivo → selecciona PDF → sube directamente
5. Sistema muestra preview y confirma ✅
```

---

## 🔄 ÉPICA 5: FLUJOS DE CONVERSIÓN, COLECTIVOS Y ALERTAS

**Objetivo:** Automatizar los momentos clave del viaje del cliente, gestionar la complejidad del crédito colectivo y empoderar al asesor con notificaciones proactivas.

### HU #15: Transición Asistida de Ahorro a Compraventa

**Como** asesor
**Quiero** ser notificado cuando un cliente cumple su meta de ahorro y tener las herramientas para guiarlo en la compra final
**Para que** la conversión de un prospecto en ahorro a un cliente activo sea fluida

**Criterios de Aceptación:**
- ✅ Un trigger en el backend debe detectar cuando:
  ```
  saldo_actual >= meta_ahorro
  ```
- ✅ El sistema envía una alerta al asesor vía WebSocket
- ✅ El asesor debe tener en su PWA los botones:
  - `Liquidar de Contado`
  - `Convertir a Venta a Plazo`

**Flujo:**
```
1. Cliente alcanza meta de ahorro: $60,000 MXN
2. Backend detecta: saldo_actual >= meta_ahorro
3. Envía alerta al asesor: "🎉 Juan Pérez cumplió su meta!"
4. Asesor abre expediente → ve botones:
   [Liquidar de Contado] [Convertir a Venta a Plazo]
5. Asesor selecciona opción → inicia flujo de compraventa
```

---

### HU #16: Gestión de Grupos de Crédito Colectivo (Tanda)

**Como** asesor
**Quiero** crear y administrar un grupo de "Tanda", definiendo el número de integrantes, la meta de ahorro y agregando miembros con estado "Activo" o "Pendiente"
**Para que** pueda iniciar y gestionar un esquema de ahorro y crédito colectivo

**Integraciones:**
- Odoo (para crear una Cuenta Analítica Maestra para el grupo)

**Flujo:**
```
1. Asesor → + Nuevo Grupo TANDA
2. Define:
   - Nombre: "Ruta Centro - Tanda 2024"
   - Número de unidades: 10
   - Meta de ahorro por unidad: $60,000 MXN
   - Meta total: $600,000 MXN
3. Agrega miembros:
   - Juan Pérez (ACTIVO)
   - María López (ACTIVO)
   - Pedro Ramírez (PENDIENTE)
4. Sistema crea Cuenta Analítica Maestra en Odoo
5. Dashboard TANDA activo para el asesor
```

---

### HU #17: Simulador de Escenarios para Tandas

**Como** asesor
**Quiero** un simulador en la PWA que me permita modelar escenarios de Tanda cambiando el número de integrantes
**Para que** pueda demostrarle al líder de la ruta el beneficio de un grupo más grande (menor aportación inicial por miembro)

**Criterios de Aceptación:**
- ✅ El cotizador de Tanda debe tener un input para el **Número de Unidades (Integrantes)**
- ✅ Al cambiar este número, métricas como:
  - Aportación Promedio por Miembro
  - Pago Mensual Máximo
  - ...deben recalcularse en tiempo real

**Ejemplo:**
```
SIMULADOR TANDA
┌────────────────────────────────────┐
│ Número de Integrantes: [10] ▼      │
│ Valor por Unidad: $400,000 MXN     │
│ Meta de Ahorro: $60,000 MXN/unidad │
├────────────────────────────────────┤
│ MÉTRICAS CALCULADAS:               │
│ • Aportación por miembro: $6,000   │
│ • Pago Mensual Máximo: $14,520     │
│ • Total Financiado: $3.4M MXN      │
├────────────────────────────────────┤
│ [Cambiar a 12 integrantes]         │
│ → Aportación baja a $5,000 ✅      │
└────────────────────────────────────┘
```

Ver **LOGICA_MATEMATICA.md Sección 9** para fórmulas completas.

---

### HU #18: Dashboard de Tanda con "Doble Aportación"

**Como** asesor
**Quiero** un dashboard para cada Tanda que muestre el "efecto bola de nieve": la meta de pago de la deuda acumulada y la meta de ahorro para el siguiente enganche
**Para que** pueda transparentar y gestionar la compleja situación financiera del grupo

**Criterios de Aceptación:**
- ✅ La PWA debe mostrar dos módulos:
  1. **"Pago Mensual (Deuda Colectiva)"**
  2. **"Ahorro para Enganche (Siguiente Unidad)"**
- ✅ A medida que se entregan unidades:
  - La meta de pago mensual debe **aumentar**
  - La meta de ahorro se debe **reiniciar**

**Ejemplo:**
```
DASHBOARD TANDA: Ruta Centro 2024
┌────────────────────────────────────┐
│ Unidades entregadas: 3/10          │
├────────────────────────────────────┤
│ 💰 DEUDA COLECTIVA ACTUAL          │
│ Unidades 1-3 en financiamiento     │
│ Pago Mensual: $29,640 MXN          │
│ Estado: ✅ AL DÍA                   │
├────────────────────────────────────┤
│ 🎯 AHORRO PARA SIGUIENTE UNIDAD    │
│ Meta: $60,000 MXN                  │
│ Avance: $45,000 MXN (75%)          │
│ Faltante: $15,000 MXN              │
├────────────────────────────────────┤
│ [Ver Detalle por Miembro]          │
└────────────────────────────────────┘
```

Ver **LOGICA_MATEMATICA.md Sección 9** para lógica de doble aportación.

---

### HU #19: Sistema de Alertas Inteligentes

**Como** asesor
**Quiero** recibir notificaciones en tiempo real sobre hitos importantes y riesgos potenciales
**Para que** la comunicación sea proactiva y pueda anticiparme a los problemas

**Criterios de Aceptación:**
Implementar un sistema de alertas vía **WebSocket** para eventos como:
- ✅ **Expediente Listo para Análisis** (todos los docs subidos)
- ✅ **Crédito Aprobado** (HASE score ≥ threshold)
- ✅ **Cliente Atorado en un Paso** (sin actividad 7+ días)
- ✅ **Meta de Ahorro Colectivo Alcanzada** (saldo_tanda >= meta)

Las notificaciones deben ser **accionables** (botón de acción directa).

**Integraciones:** WebSocket

**Ejemplo de Notificación:**
```
┌────────────────────────────────────┐
│ 🎉 Meta de Ahorro Alcanzada!       │
│ Juan Pérez - Ahorro Individual     │
│ $60,000 / $60,000 (100%)           │
│ [Iniciar Proceso de Compra]        │
└────────────────────────────────────┘
```

---

### HU #20: Generación de Estados de Cuenta

**Como** cliente o asesor
**Quiero** poder ver y descargar un estado de cuenta de mi plan de ahorro o de mi venta a plazo
**Para que** tenga total transparencia y un registro formal de mis movimientos

**Integraciones:** Odoo

**Ejemplo de Estado de Cuenta:**
```
ESTADO DE CUENTA
Cliente: Juan Pérez
Plan: Ahorro Individual
Periodo: 01-Ene-2024 a 31-Oct-2024

TRANSACCIONES:
| Fecha     | Tipo      | Monto      | Saldo    |
|-----------|-----------|------------|----------|
| 15-Oct-24 | Recaudo   | $1,200 MXN | $45,000  |
| 10-Oct-24 | Conekta   | $5,000 MXN | $43,800  |
| 05-Oct-24 | Conekta   | $2,500 MXN | $38,800  |

RESUMEN:
Ahorro Total: $45,000 MXN
Meta: $60,000 MXN
Completitud: 75%

[Descargar PDF] [Enviar por Email]
```

---

## 🔗 ÉPICA 6: CONEXIÓN A PRODUCCIÓN Y PUESTA EN MARCHA

**Objetivo:** Reemplazar todas las simulaciones con las APIs reales y preparar la plataforma para el lanzamiento.

### HU #21: Integración Real con API de GNV

**Como** desarrollador
**Quiero** integrar el cliente API real de nuestro socio de GNV
**Para que** podamos activar reglas de recaudo y consumir datos de transacciones de forma automática

**Integraciones:** API de GNV

**Endpoints a implementar:**
```typescript
// Activar regla de recaudo
POST /api/gnv/rules/activate
{
  "plate": "ABC-123-XYZ",
  "surcharge": 0.50,  // MXN/kg
  "customer_id": "uuid"
}

// Consultar transacciones
GET /api/gnv/transactions?plate=ABC-123-XYZ&start_date=2024-01-01
```

---

### HU #22: Integración Real con Motores de Riesgo

**Como** desarrollador
**Quiero** reemplazar las simulaciones de KIBAN y HASE con sus APIs reales
**Para que** el proceso de análisis de riesgo sea funcional y se base en datos reales

**Integraciones:**
- KIBAN (análisis financiero)
- HASE (scoring alternativo)

Ver **LOGICA_MATEMATICA.md Sección 2** para fórmula HASE completa.

---

### HU #23: Integración Real con Firma y Pagos

**Como** desarrollador
**Quiero** reemplazar las simulaciones de Mifiel y Conekta con sus APIs reales
**Para que** la firma de contratos sea legalmente vinculante y los pagos se procesen de forma segura

**Integraciones:**
- Mifiel (firma digital)
- Conekta (pagos México)

Ver **CORE_FASE4_INTEGRACIONES.md** para detalles de integración.

---

### HU #24: Integración Real con Odoo

**Como** desarrollador
**Quiero** que todos los flujos que interactúan con Odoo (CRM, Contabilidad, Ventas) se conecten a nuestra instancia de producción
**Para que** Odoo funcione como nuestro ledger centralizado

**Integraciones:** Odoo (producción; configuración detallada en `ANEXO_ODOO_SETUP.md`)

**Módulos de Odoo a integrar:**
- CRM (gestión de oportunidades)
- Contabilidad (cuentas analíticas, transacciones)
- Ventas (cotizaciones, contratos)
- Inventario (vehículos disponibles)

---

### HU #25: Onboarding del Primer Cliente Piloto

**Como** Head of Growth
**Quiero** utilizar la PWA para procesar la solicitud de nuestro primer cliente real de punta a punta
**Para que** podamos validar el flujo completo en un entorno de producción y obtener retroalimentación directa del mercado

**Criterios de Aceptación:**
- ✅ Un cliente real completa su expediente
- ✅ Su solicitud pasa por el flujo de análisis con datos reales (KIBAN + HASE)
- ✅ Firma un contrato legalmente vinculante (Mifiel)
- ✅ Realiza un pago real (Conekta o GNV)
- ✅ La solicitud llega al estado **"COMPLETADA"** con todas las integraciones reales funcionando

**Flujo Completo:**
```
1. Asesor inicia nueva oportunidad con cliente piloto
2. Cliente sube documentos reales (INE, comprobante, etc.)
3. Sistema ejecuta scoring HASE con datos reales
4. Si aprobado → genera contrato → envía a Mifiel
5. Cliente firma electrónicamente
6. Cliente realiza primer pago vía Conekta
7. Transacción se registra en Odoo
8. Estado: COMPLETADA ✅
9. Equipo revisa logs y obtiene feedback
```

---

## ✅ CHECKLIST DE RECONSTRUCCIÓN (ESTADO FINAL ESPERADO)

| Módulo / Funcionalidad | ¿Tiene? | Notas Clave |
|------------------------|---------|-------------|
| **ARQUITECTURA** |
| Backend NestJS + Frontend Angular | ❌ No | Prioridad #1: Reestablecer la base |
| WebSocket en Tiempo Real | ❌ No | Reconstruir el WebSocketGateway |
| **SUPER APP ASESOR** |
| Árbol de Decisión Inicial | ❌ No | Guía al asesor por Tipo de Venta y Mercado |
| Gestión de Ecosistemas (Rutas) | ❌ No | Flujo "Route-First" para EdoMex |
| Configurador de Paquetes Dinámico | ❌ No | Se adapta a Contado/Financiado y al Mercado |
| Cotizador y Amortización Contextual | ❌ No | Aplica reglas de negocio (tasas, plazos, enganches) |
| Configuración de Planes Híbridos | ❌ No | Permite Recaudación y Aportaciones Voluntarias |
| Dashboard de Conciliación | ❌ No | Visión 360° del estado financiero del cliente |
| Simulador de Escenarios de Tanda | ❌ No | Modela el impacto de cambiar el número de integrantes |
| **CORE BANCARIO Y FINANCIERO** |
| Expediente Digital Dinámico | ❌ No | Solicita los documentos correctos para cada flujo |
| Gestión de Archivos Flexible | ❌ No | Acepta Imágenes y PDF, con compresión |
| **INTEGRACIONES CLAVE** |
| API de GNV | ❌ No | Crítico: Construir el servicio para activar y consultar recaudos |
| Odoo, Metamap, KIBAN, etc. | ❌ No | Reconstruir todos los clientes API |
| **FLUJOS DE NEGOCIO COMPLETOS** |
| Venta de Contado Express | ❌ No | Flujo universal y simplificado |
| Venta a Plazo (Individual y Ecosistema) | ❌ No | Con pago híbrido y requisitos contextuales |
| Ahorro Programado Híbrido | ❌ No | Flujo completo de ahorro flexible |
| Crédito Colectivo (Tanda) | ❌ No | Lógica de ahorro y deuda escalonada |
| Principio "Asesor Siempre Presente" | ❌ No | Integrado en cada UI y flujo de comunicación |

---

## 📊 RESUMEN EJECUTIVO

### Estadísticas del Blueprint

| Métrica | Valor |
|---------|-------|
| **Total de Épicas** | 6 |
| **Total de Historias de Usuario** | 25 |
| **Roles involucrados** | Desarrollador, Asesor, Admin, Cliente, Head of Growth |
| **Integraciones requeridas** | 8 (GNV, Odoo, Conekta, Mifiel, KIBAN, HASE, Metamap, WebSocket) |

### Priorización de Épicas (Recomendada)

1. **Épica 1: Núcleo Arquitectónico** (HU #01-#04) → Base técnica
2. **Épica 3: Motor Financiero** (HU #07-#12) → Core de negocio
3. **Épica 4: Expediente Digital** (HU #13-#14) → Gestión documental
4. **Épica 2: Flujo Route-First** (HU #05-#06) → Colateral social
5. **Épica 5: Conversión y Alertas** (HU #15-#20) → UX avanzada
6. **Épica 6: Puesta en Producción** (HU #21-#25) → Go-live

---

## 🔗 ENLACES RELACIONADOS

- **LOGICA_MATEMATICA.md** - Fórmulas de cotización, amortización, HASE, TANDA
- **CORE_FASE2_ARQUITECTURA.md** - Stack técnico (NestJS, Angular, PostgreSQL)
- **CORE_FASE4_INTEGRACIONES.md** - Detalles de las 8 integraciones
- **CORE_FASE3C_REGLAS_NEGOCIO.md** - Reglas de negocio detalladas (próximo documento)

---

**Versión:** Blueprint Maestro v6.0
**Última actualización:** Octubre 2024
**Estado:** ❌ Pendiente de implementación (0/25 completadas)
