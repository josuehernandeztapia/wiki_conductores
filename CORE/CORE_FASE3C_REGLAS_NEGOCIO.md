# FASE 3C: REGLAS DE NEGOCIO (BUSINESS RULES)

**Playbook de Reglas de Negocio v1.0**

---

## 📋 PROPÓSITO

Este documento es la **fuente única de verdad** para todas las reglas, lineamientos y requisitos por producto y mercado.

La PWA del asesor debe ser programada para **ejecutar y validar estas reglas automáticamente**.

---

## 🗺️ ESTRUCTURA: 2 MERCADOS, 4 PRODUCTOS

| Mercado | Productos Disponibles | Características Clave |
|---------|----------------------|----------------------|
| **Aguascalientes** | Venta Contado, Venta a Plazo (Remanente) | Individual, sin colateral social |
| **Estado de México** | Venta Contado, Venta a Plazo, Ahorro Programado, TANDA | Ecosistema "Route-First", colateral social obligatorio |

---

## 🏙️ MERCADO 1: AGUASCALIENTES

### Características del Mercado

- **Modelo de Negocio Principal:** Venta Individual, enfocada en clientes con alta liquidez
- **Colateral Social:** ❌ **NO se requiere** Carta Aval ni Convenio de Dación en Pago
- **Target:** Conductores con mayor capacidad de ahorro y flujo de efectivo

---

### PRODUCTO 1: VENTA DIRECTA (CONTADO)

| Atributo | Regla / Requisito |
|----------|-------------------|
| **Paquete Base** | Vagoneta H6C (19 Pasajeros) - **$799,000 MXN** |
| **Componentes** | Conversión GNV (**$54,000 MXN**) es **opcional**. El asesor debe confirmar con el cliente si se incluye |
| **Expediente Requerido** | **Express:** INE Vigente, Comprobante de Domicilio, Constancia de Situación Fiscal |
| **Contrato** | Contrato de Compraventa simple |
| **Forma de Pago** | **SPEI (Transferencia)** por el monto total, generado desde la PWA del asesor |

**Configuración en PWA:**
```
Mercado: Aguascalientes
Tipo Venta: Contado
┌────────────────────────────────────┐
│ Vagoneta H6C (19p)  $799,000 MXN   │
│ ☐ GNV (Opcional)     $54,000 MXN   │
├────────────────────────────────────┤
│ TOTAL: $799,000 - $853,000 MXN     │
│ Forma de pago: SPEI                │
└────────────────────────────────────┘
```

---

### PRODUCTO 2: VENTA A PLAZO (REMANENTE)

| Atributo | Regla / Requisito |
|----------|-------------------|
| **Paquete Base** | Vagoneta H6C (19 Pasajeros) con **Conversión GNV incluida por defecto**. Valor total: **$853,000 MXN** |
| **Límite de Financiamiento** | Se puede financiar un máximo del **40%** del valor total del paquete (**$341,200 MXN**) |
| **Enganche Mínimo** | **60%** del valor total del paquete (**$511,800 MXN**) |
| **Plazos Disponibles** | **12 y 24 meses únicamente** |
| **Tasa de Interés Fija** | **25.5% anual** |
| **Expediente Requerido** | **Individual:** INE Vigente, Comprobante de domicilio, Tarjeta de circulación, Concesión, Constancia de situación fiscal |
| **Contrato** | Contrato de Venta a Plazo |

**Fórmulas:**
```python
# Aguascalientes - Venta a Plazo (Remanente)
VALOR_TOTAL = 853_000  # MXN (Vagoneta + GNV)
ENGANCHE_MIN = VALOR_TOTAL * 0.60  # $511,800 MXN
FINANCIAMIENTO_MAX = VALOR_TOTAL * 0.40  # $341,200 MXN

TASA_ANUAL = 0.255  # 25.5%
PLAZOS = [12, 24]  # meses

# Pago mensual (fórmula French)
r = TASA_ANUAL / 12
n = plazo_seleccionado
P = monto_financiado

PMT = P * (r * (1 + r)**n) / ((1 + r)**n - 1)
```

**Ejemplo de Cotización:**
```
AGUASCALIENTES - VENTA A PLAZO (REMANENTE)
Cliente: Juan Pérez
Valor del Paquete: $853,000 MXN
Enganche: $511,800 MXN (60%)
Monto a Financiar: $341,200 MXN (40%)
Tasa: 25.5% anual
Plazo: 24 meses
Pago Mensual: $18,203 MXN
```

---

## 🏙️ MERCADO 2: ESTADO DE MÉXICO (EDOMEX)

### Características del Mercado

- **Modelo de Negocio Principal:** Ecosistema **"Route-First"**, basado en colateral social
- **Colateral Social:** ✅ **Se requiere:**
  - Convenio Marco con la Ruta (firmado por representante legal)
  - Carta Aval por cada miembro (firmada por líder de ruta)
  - Convenio de Dación en Pago (compromiso de entrega de unidad en caso de default)
- **Target:** Rutas organizadas con líder y miembros comprometidos

---

### PRODUCTO 1: VENTA DIRECTA (CONTADO)

| Atributo | Regla / Requisito |
|----------|-------------------|
| **Paquete Base** | Vagoneta H6C (Ventanas) - **$749,000 MXN** |
| **Componentes** | El asesor debe seleccionar una de dos opciones:<br>☐ Solo Unidad Base<br>☐ Incluir **Paquete Productivo Completo** |
| **Expediente Requerido** | **Express:** INE Vigente, Comprobante de Domicilio, Constancia de Situación Fiscal |
| **Contrato** | Contrato de Compraventa simple |
| **Forma de Pago** | **SPEI (Transferencia)** por el monto total |

**Paquete Productivo Completo:**
```yaml
Componentes:
  - Vagoneta H6C: $749,000 MXN
  - Conversión GNV: $54,000 MXN
  - Paquete Tecnológico: $12,000 MXN
  - Bancas adicionales: $22,000 MXN

TOTAL: $837,000 MXN
```

---

### PRODUCTO 2: VENTA A PLAZO (INDIVIDUAL O COLECTIVO)

| Atributo | Regla / Requisito |
|----------|-------------------|
| **Paquete Base** | **Paquete Productivo Completo es obligatorio** y no opcional. Incluye:<br>- Vagoneta ($749K)<br>- GNV ($54K)<br>- Paquete Tec ($12K)<br>- Bancas ($22K)<br>**Total: $837,000 MXN** |
| **Seguro** | Se financia **por defecto**. El costo anual de **$36,700 MXN** se multiplica por los años del plazo y se suma al valor total.<br>Es **opcional solo si el cliente presenta una póliza externa validada** |
| **Enganche Mínimo** | **Individual:** 15-20% (default 20%)<br>**Colectivo (Tanda):** 15% (incentivo) |
| **Plazos Disponibles** | **48 y 60 meses únicamente** |
| **Tasa de Interés Fija** | **29.9% anual** |
| **Pago Híbrido** | El plan de pagos mensual puede combinar:<br>- **Recaudación por GNV** (con sobreprecio no mayor a $10.00 MXN/kg)<br>- **Aportaciones Voluntarias** (Conekta: SPEI, Tarjeta, OXXO)<br>El asesor lo configura en la PWA |
| **Expediente Requerido** | **Completo:** Todos los documentos del individual de AGS **MÁS:**<br>- Factura de unidad actual<br>- Carta Aval de Ruta<br>- Convenio de Dación en Pago |
| **Contrato** | Contrato de Venta a Plazo (con cláusulas de pago híbrido y colateral social) |

**Fórmulas:**
```python
# Estado de México - Venta a Plazo
PAQUETE_PRODUCTIVO = 837_000  # MXN (obligatorio)
SEGURO_ANUAL = 36_700  # MXN

# Cálculo de seguro según plazo
plazo_meses = 48  # o 60
plazo_anos = plazo_meses / 12
COSTO_SEGURO_TOTAL = SEGURO_ANUAL * plazo_anos

# Valor total financiable
VALOR_TOTAL = PAQUETE_PRODUCTIVO + COSTO_SEGURO_TOTAL

# Enganches
if tipo_venta == "Individual":
    ENGANCHE_MIN_PCT = 0.20  # 20% default (puede ser 15%)
else:  # Colectivo (TANDA)
    ENGANCHE_MIN_PCT = 0.15  # 15% (incentivo)

ENGANCHE = VALOR_TOTAL * ENGANCHE_MIN_PCT
MONTO_FINANCIADO = VALOR_TOTAL - ENGANCHE

# Tasa y PMT
TASA_ANUAL = 0.299  # 29.9%
r = TASA_ANUAL / 12
n = plazo_meses

PMT = MONTO_FINANCIADO * (r * (1 + r)**n) / ((1 + r)**n - 1)
```

**Ejemplo de Cotización (Individual):**
```
ESTADO DE MÉXICO - VENTA A PLAZO (INDIVIDUAL)
Cliente: María López
Paquete Productivo: $837,000 MXN
Seguro (48 meses): $146,800 MXN
Valor Total: $983,800 MXN
Enganche: $196,760 MXN (20%)
Monto a Financiar: $787,040 MXN
Tasa: 29.9% anual
Plazo: 48 meses
Pago Mensual: $26,430 MXN

Método de Pago: HÍBRIDO
  - Recaudo GNV: ~$8,000/mes
  - Aportación Voluntaria: ~$18,430/mes
```

**Ejemplo de Cotización (Colectivo - TANDA 10 unidades):**
```
ESTADO DE MÉXICO - TANDA (10 INTEGRANTES)
Grupo: Ruta Centro 2024
Paquete por Unidad: $837,000 MXN
Seguro por Unidad (48m): $146,800 MXN
Valor Total por Unidad: $983,800 MXN
Enganche por Unidad: $147,570 MXN (15%)
Enganche Total Grupo: $1,475,700 MXN

META DE AHORRO INICIAL: $1,475,700 MXN
Aportación por Miembro: $147,570 MXN

Al alcanzar meta → Primera unidad entregada
Financiamiento: $836,230 MXN
Pago Mensual Grupo: $28,080 MXN
```

Ver **LOGICA_MATEMATICA.md Sección 9** para lógica completa de TANDA.

---

### PRODUCTO 3: AHORRO PROGRAMADO (SOLO EDOMEX)

| Atributo | Regla / Requisito |
|----------|-------------------|
| **Contrato Inicial** | **Contrato Promesa de Compraventa** |
| **Meta de Ahorro** | El enganche correspondiente al plan de Venta a Plazo (ej. **15%** del paquete completo para una Tanda, **20%** para Individual) |
| **Método de Ahorro** | **Híbrido por defecto**. Se pueden activar:<br>- Recaudación (API de GNV)<br>- Aportaciones Voluntarias (Conekta) |
| **Expediente Requerido** | **Básico:** INE, Comprobante de Domicilio<br>Si se activa el recaudo, se añade: Tarjeta de Circulación y Concesión |
| **Conversión a Venta** | Al alcanzar la meta, la PWA inicia el flujo de **Venta a Plazo**, aplicando el saldo ahorrado como enganche y solicitando el **resto del expediente completo** |

**Flujo de Ahorro Programado:**
```
1. Cliente inicia Ahorro Programado
2. Define meta de ahorro (15-20% del valor total)
3. Configura método híbrido:
   ☑️ Recaudo GNV (placas: ABC-123-XYZ, sobreprecio: $0.50/kg)
   ☑️ Aportaciones Voluntarias (SPEI/Tarjeta)
4. Cliente ahorra durante N meses
5. Sistema monitorea: saldo_actual >= meta_ahorro
6. Al cumplir meta → Alerta al asesor
7. Asesor inicia conversión a Venta a Plazo:
   - Saldo ahorrado se aplica como enganche
   - Solicita expediente completo
   - Genera contrato de Venta a Plazo
   - Cliente financia el remanente
```

Ver **LOGICA_MATEMATICA.md Sección 10** para fórmulas de ahorro.

---

### PRODUCTO 4: TANDA (CRÉDITO COLECTIVO - SOLO EDOMEX)

**Nota:** TANDA es una modalidad especial de Ahorro Programado + Venta a Plazo para grupos.

| Atributo | Regla / Requisito |
|----------|-------------------|
| **Tipo de Cliente** | Grupo de N integrantes (típicamente 10-15) vinculados a una Ruta |
| **Contrato Inicial** | Contrato Promesa de Compraventa (colectivo) |
| **Meta de Ahorro Inicial** | Enganche para la primera unidad (15% del paquete completo) |
| **Lógica de Doble Aportación** | Una vez entregada la primera unidad:<br>1. **Pago de deuda acumulada** (unidades ya entregadas)<br>2. **Ahorro para siguiente enganche** (siguiente unidad)<br>Ambos en paralelo |
| **Plazos** | 48 o 60 meses |
| **Tasa** | 29.9% anual |
| **Método de Pago** | Híbrido (Recaudo + Aportaciones) |
| **Expediente** | Completo por cada miembro + Convenio Marco de la Ruta |

**Lógica de TANDA (Debt-First Allocation):**
```python
# Al recibir pago del grupo
pago_total_recibido = 30_000  # MXN (ejemplo)

# 1. Calcular deuda mensual (unidades ya entregadas)
unidades_entregadas = 3
pago_mensual_por_unidad = 28_080  # MXN
deuda_mensual = unidades_entregadas * pago_mensual_por_unidad  # $84,240

# 2. Asignar pago
if pago_total_recibido >= deuda_mensual:
    # Pagar deuda completa
    asignar_a_deuda = deuda_mensual
    asignar_a_ahorro = pago_total_recibido - deuda_mensual
else:
    # Pagar lo que se pueda de deuda, ahorro = 0
    asignar_a_deuda = pago_total_recibido
    asignar_a_ahorro = 0
    # Marcar como ATRASADO

# 3. Verificar si se alcanzó meta de ahorro para siguiente unidad
if saldo_ahorro_actual >= meta_enganche_siguiente:
    entregar_siguiente_unidad()
    unidades_entregadas += 1
    saldo_ahorro_actual = 0  # Reiniciar ahorro
```

Ver **LOGICA_MATEMATICA.md Sección 9** para implementación completa.

---

## 📑 REQUISITOS DOCUMENTALES POR MERCADO Y PRODUCTO

### Aguascalientes

| Producto | Checklist Requerido | Notas |
|----------|--------------------|-------|
| **Contado** | **Express**: INE vigente, Comprobante de domicilio, Constancia de Situación Fiscal | Se liquida vía SPEI único; no hay requisitos de colateral social |
| **Venta a Plazo (Remanente)** | **Individual**: Checklist Express **más** Tarjeta de circulación, Concesión, Constancia fiscal actualizada | Mismo expediente aplica para los tramos 12 y 24 meses; no se solicita factura previa ni aval |

### Estado de México

| Producto | Checklist Requerido | Notas |
|----------|--------------------|-------|
| **Contado** | **Express**: INE, Comprobante de domicilio, Constancia fiscal | Si el cliente adquiere el Paquete Productivo completo, el contrato debe incluir los componentes GNV/Tec/Bancas |
| **Venta a Plazo (Individual/Colectivo)** | **Completo**: Checklist Individual **más** Factura de unidad actual, Carta Aval de Ruta, Convenio de Dación en Pago | Para planes con recaudación se adjuntan placas y concesión con el registro del sobreprecio GNV |
| **Ahorro Programado** | **Básico**: INE + Comprobante domicilio; si se enciende recaudación se añaden Tarjeta de circulación y Concesión | Cuando el saldo ahorro ≥ meta de enganche, la PWA dispara la conversión a Venta y solicita el **expediente completo** |
| **TANDA (Crédito Colectivo)** | **Completo por miembro**: Checklist Individual + Colateral social (Carta Aval + Convenio Dación) + Convenio Marco de ruta activo | Antes de adjudicar unidades, cada miembro debe estar vinculado en Odoo a su ruta y contar con expediente sin faltantes |

> **Recordatorio PWA:** la función `getRequiredDocuments()` ya contempla estas variantes dependiendo del mercado, producto y si el flujo activa recaudación (`CORE_FASE3C_REGLAS_NEGOCIO.md:399`).

### 📈 TIR Mínima Admitida por Producto

| Mercado / Producto | Tasa nominal base | TIR mínima posterior a restructura | Comentarios |
|--------------------|-------------------|-----------------------------------|-------------|
| **AGS - Venta a Plazo (Remanente)** | 25.5% anual | **25.5%** | Cualquier escenario que reduzca la TIR por debajo de la tasa nominal se rechaza automáticamente para preservar la estructura de capital interna. |
| **EDOMEX - Venta a Plazo Individual** | 29.9% anual | **29.9%** | El motor de protección (diferir, recalendar, step-down) debe mantener TIR ≥ 29.9%; si cae, la restructura se marca como inválida. |
| **EDOMEX - TANDA (Colectivo)** | 29.9% anual | **29.9%** | Aunque el flujo es grupal, la TIR post-escenario debe igualar la tasa nominal para sostener la rentabilidad del pool. |
| **Crédito Directo Nacional (futuros despliegues)** | 14‑20% (según tier interno) | **Igual a la tasa nominal aplicable** | Referencia para cualquier producto donde la tasa dependa del score; `validate_protection_scenario` debe recibir `min_irr = rate`. |

> Estos umbrales alimentan el validador de la Sección 7 de `LOGICA_MATEMATICA.md`. El motor BFF debe recibir `min_irr` conforme al producto seleccionado para bloquear restructuras que comprometan la rentabilidad.

## 📊 TABLA COMPARATIVA DE REGLAS

### Comparación por Mercado

| Atributo | Aguascalientes | Estado de México |
|----------|----------------|------------------|
| **Modelo** | Individual | Ecosistema "Route-First" |
| **Colateral Social** | ❌ NO requerido | ✅ Obligatorio (Carta Aval + Convenio Dación) |
| **Paquete Base** | Vagoneta H6C 19p | Vagoneta H6C Ventanas |
| **GNV** | Opcional | Obligatorio |
| **Paquete Productivo** | Opcional | Obligatorio |
| **Tasa (Remanente/Plazo)** | 25.5% | 29.9% |
| **Plazos** | 12-24 meses | 48-60 meses |
| **Enganche Mínimo** | 60% (Remanente), N/A (Plazo) | 15-20% |
| **Pago Híbrido** | ❌ NO disponible | ✅ Disponible (Recaudo + Aportaciones) |
| **Ahorro Programado** | ❌ NO disponible | ✅ Disponible |
| **TANDA** | ❌ NO disponible | ✅ Disponible |

---

### Comparación de Productos EdoMex

| Atributo | Contado | Venta a Plazo | Ahorro Programado | TANDA |
|----------|---------|---------------|-------------------|-------|
| **Paquete Productivo** | Opcional | Obligatorio | N/A (definido al convertir) | Obligatorio |
| **Seguro** | ❌ NO | ✅ Sí (financiado) | ❌ NO | ✅ Sí (financiado) |
| **Enganche** | N/A (100%) | 15-20% | 0% (ahorra para enganche) | 15% colectivo |
| **Método Pago** | SPEI único | Híbrido (Recaudo + Aportaciones) | Híbrido | Híbrido |
| **Expediente** | Express | Completo | Básico → Completo al convertir | Completo |
| **Colateral Social** | ❌ NO | ✅ Sí | ⚠️ Al convertir | ✅ Sí |

---

## 🔧 VALIDACIONES AUTOMÁTICAS EN PWA

La PWA debe implementar las siguientes validaciones:

### 1. Validación de Mercado y Tipo de Venta

```typescript
function validateMarketAndProduct(
  market: 'AGS' | 'EDOMEX',
  productType: 'CONTADO' | 'PLAZO' | 'AHORRO' | 'TANDA'
): ValidationResult {
  // TANDA solo disponible en EdoMex
  if (productType === 'TANDA' && market !== 'EDOMEX') {
    return { valid: false, error: 'TANDA solo disponible en Estado de México' };
  }

  // Ahorro Programado solo en EdoMex
  if (productType === 'AHORRO' && market !== 'EDOMEX') {
    return { valid: false, error: 'Ahorro Programado solo disponible en Estado de México' };
  }

  return { valid: true };
}
```

---

### 2. Validación de Enganche y Financiamiento

```typescript
function validateDownPayment(
  market: 'AGS' | 'EDOMEX',
  productType: string,
  totalValue: number,
  downPayment: number
): ValidationResult {
  if (market === 'AGS' && productType === 'PLAZO') {
    // Aguascalientes Remanente: 60% enganche mínimo
    const minDownPayment = totalValue * 0.60;
    if (downPayment < minDownPayment) {
      return {
        valid: false,
        error: `Enganche mínimo: ${minDownPayment.toFixed(2)} MXN (60%)`
      };
    }
  }

  if (market === 'EDOMEX' && productType === 'PLAZO') {
    // Estado de México: 15-20%
    const minDownPayment = totalValue * 0.15;
    const maxRecommended = totalValue * 0.20;
    if (downPayment < minDownPayment) {
      return {
        valid: false,
        error: `Enganche mínimo: ${minDownPayment.toFixed(2)} MXN (15%)`
      };
    }
  }

  return { valid: true };
}
```

---

### 3. Validación de Expediente Dinámico

```typescript
function getRequiredDocuments(
  market: 'AGS' | 'EDOMEX',
  productType: 'CONTADO' | 'PLAZO' | 'AHORRO' | 'TANDA',
  hasRecaudo: boolean
): string[] {
  const baseExpress = ['INE', 'Comprobante Domicilio', 'CSF'];
  const baseIndividual = [...baseExpress, 'Tarjeta Circulación', 'Concesión'];
  const completeEdoMex = [...baseIndividual, 'Factura Unidad', 'Carta Aval Ruta', 'Convenio Dación'];

  if (productType === 'CONTADO') {
    return baseExpress;
  }

  if (market === 'AGS' && productType === 'PLAZO') {
    return baseIndividual;
  }

  if (market === 'EDOMEX' && productType === 'PLAZO') {
    return completeEdoMex;
  }

  if (market === 'EDOMEX' && productType === 'AHORRO') {
    if (hasRecaudo) {
      return [...baseExpress, 'Tarjeta Circulación', 'Concesión'];
    }
    return baseExpress;
  }

  if (productType === 'TANDA') {
    return completeEdoMex;
  }

  return baseExpress;
}
```

---

### 4. Validación de Sobreprecio GNV

```typescript
function validateGNVSurcharge(surcharge: number): ValidationResult {
  const MAX_SURCHARGE = 10.00;  // MXN/kg

  if (surcharge > MAX_SURCHARGE) {
    return {
      valid: false,
      error: `Sobreprecio GNV no puede exceder $${MAX_SURCHARGE} MXN/kg`
    };
  }

  if (surcharge < 0) {
    return {
      valid: false,
      error: 'Sobreprecio no puede ser negativo'
    };
  }

  return { valid: true };
}
```

---

### 5. Validación de Plazos

```typescript
function validateTerm(
  market: 'AGS' | 'EDOMEX',
  productType: string,
  termMonths: number
): ValidationResult {
  const allowedTerms = {
    AGS_PLAZO: [12, 24],
    EDOMEX_PLAZO: [48, 60],
    EDOMEX_TANDA: [48, 60]
  };

  let validTerms: number[] = [];

  if (market === 'AGS' && productType === 'PLAZO') {
    validTerms = allowedTerms.AGS_PLAZO;
  } else if (market === 'EDOMEX' && (productType === 'PLAZO' || productType === 'TANDA')) {
    validTerms = allowedTerms.EDOMEX_PLAZO;
  }

  if (!validTerms.includes(termMonths)) {
    return {
      valid: false,
      error: `Plazo debe ser uno de: ${validTerms.join(', ')} meses`
    };
  }

  return { valid: true };
}
```

---

## 🔁 PUNTOS OPERATIVOS CLAVE (VERSIÓN REVISADA)

- **Enganches y Financiamiento**: AGS exige 60 % de enganche (financiamiento 40 %) para el remanente, mientras EDOMEX admite 15‑20 % (individual) o 15 % (TANDA) y financia seguro + Paquete Productivo.
- **Plazos y Tasas**: Validar 12/24 meses a 25.5 % anual en AGS frente a 48/60 meses a 29.9 % en EDOMEX (`validateTerm`).
- **Pago Híbrido y Sobreprecio**: Solo en EDOMEX; requiere definir porcentaje Recaudo/Aportaciones y respetar el máximo $10 MXN/kg (`validateGNVSurcharge`).
- **Conversión Automática Ahorro→Venta**: Al alcanzar la meta, la PWA aplica el saldo como enganche y solicita el expediente completo antes de originar el crédito.
- **TANDA Debt-First**: Los flujos grupales primero cubren deuda de unidades entregadas y luego ahorran para la siguiente adjudicación; cualquier déficit bloquea nuevas entregas.

Estas directrices se alinean con la lógica matemática (Secciones 1, 7, 9 y 10) y con las historias de usuario (HU05‑HU20), garantizando consistencia entre PWA, backend y Odoo.

---

## 📋 CHECKLIST DE IMPLEMENTACIÓN

| Regla | Implementada en PWA | Notas |
|-------|---------------------|-------|
| **Validación de Mercado** | ❌ | Árbol de decisión inicial |
| **Configurador de Paquetes** | ❌ | Dinámico según mercado |
| **Validación de Enganche** | ❌ | AGS 60%, EdoMex 15-20% |
| **Validación de Plazos** | ❌ | AGS 12-24m, EdoMex 48-60m |
| **Validación de Tasas** | ❌ | AGS 25.5%, EdoMex 29.9% |
| **Checklist Dinámico** | ❌ | Según tipo venta y mercado |
| **Pago Híbrido** | ❌ | Solo EdoMex |
| **Validación Sobreprecio GNV** | ❌ | Max $10 MXN/kg |
| **Lógica TANDA** | ❌ | Debt-first allocation |
| **Conversión Ahorro → Venta** | ❌ | Trigger al alcanzar meta |

---

## 🔗 ENLACES RELACIONADOS

- **CORE_FASE3B_HISTORIAS_USUARIO.md** - User Stories implementando estas reglas
- **LOGICA_MATEMATICA.md Sección 1** - Cotizador
- **LOGICA_MATEMATICA.md Sección 3** - Tabla de Amortización
- **LOGICA_MATEMATICA.md Sección 9** - TANDA (Debt-First Allocation)
- **LOGICA_MATEMATICA.md Sección 10** - Ahorro Individual
- **CORE_FASE4_INTEGRACIONES.md** - API de GNV, Conekta, Odoo

---

**Versión:** Playbook v1.0
**Última actualización:** Octubre 2024
**Estado:** ❌ Pendiente de implementación en PWA
