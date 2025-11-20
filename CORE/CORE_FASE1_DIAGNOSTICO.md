# CORE FASE 1: DIAGNÓSTICO DEL PROBLEMA

## 🎯 Objetivo de esta Fase
Identificar y documentar el problema central que resuelve **Conductores del Mundo**, definiendo el mercado objetivo, las barreras actuales y la propuesta de valor.

---

## 📊 Análisis del Problema

### 1. Problema Principal
**Los conductores de plataformas digitales (Uber, Didi, taxis) en México NO tienen acceso a créditos vehiculares tradicionales.**

### 2. Causas Raíz

#### A) Exclusión Financiera Tradicional
```
❌ Bancos rechazan a:
   ├── Trabajadores informales (sin nómina)
   ├── Freelancers (ingresos variables)
   ├── Sin historial crediticio formal
   └── Sin capacidad de demostrar ingresos tradicionales
```

#### B) Paradoja Operativa
```
🔄 Círculo vicioso:
   Necesitan → Vehículo para trabajar
   Pero →      No pueden conseguir crédito
   Porque →    No tienen empleo formal
   Resultado → Rentan vehículos a tasas del 30-40% anual
```

#### C) Datos de Mercado
- **4.2 millones** de conductores activos en México (2024)
- **72%** trabaja sin vehículo propio
- **$15,000-$25,000 MXN** ingreso mensual promedio
- **85%** rechazados por bancos tradicionales
- **30-40% anual** tasa de interés en rentas vehiculares

---

## 🎯 Mercado Objetivo

### Segmento Primario: Conductores de Plataformas Digitales

#### Perfil del Usuario Ideal (ICP)
```yaml
Demografía:
  Edad: 25-45 años
  Género: 80% hombres, 20% mujeres
  Ubicación: Zonas metropolitanas (CDMX, GDL, MTY)
  Estado Civil: 60% con familia

Situación Laboral:
  Actividad: Conductor tiempo completo
  Plataformas: Uber, Didi, InDrive, taxis
  Experiencia: 6+ meses activo
  Ingresos: $15,000-$35,000 MXN/mes
  Horas trabajadas: 40-60 hrs/semana

Situación Financiera:
  Historial crediticio: Limitado o nulo
  Buró: Score bajo o sin score
  Acceso bancario: Limitado
  Método pago actual: Efectivo + apps de pago

Situación Vehicular:
  Vehículo actual: Rentado o prestado
  Costo renta: $5,000-$8,000 MXN/semana
  Deseo: Vehículo propio
  Presupuesto: $200,000-$400,000 MXN
```

### Tamaño del Mercado (TAM/SAM/SOM)

```
TAM (Total Addressable Market):
└── 4.2M conductores en México
    └── Mercado potencial: $84B MXN
        (4.2M × $20K promedio crédito)

SAM (Serviceable Addressable Market):
└── 3.0M conductores sin vehículo propio (72%)
    └── Mercado serviceable: $60B MXN

SOM (Serviceable Obtainable Market - Año 1):
└── 5,000 conductores (0.17% penetración)
    └── Mercado objetivo: $100M MXN
        (5K × $200K promedio crédito)
```

---

## 🚫 Barreras Actuales

### 1. Barreras Bancarias Tradicionales

| Requisito Bancario | Conductor Típico | Resultado |
|-------------------|------------------|-----------|
| **Nómina formal** | Ingresos variables via apps | ❌ Rechazado |
| **Antigüedad laboral** | Freelance 6-12 meses | ❌ Rechazado |
| **Buró de crédito** | Sin historial / score bajo | ❌ Rechazado |
| **Avalista con propiedad** | No disponible | ❌ Rechazado |
| **Enganche 30-40%** | $60K-$120K (no tienen) | ❌ Rechazado |
| **Comprobante domicilio** | Algunos sin domicilio fijo | ❌ Rechazado |

### 2. Alternativas Existentes (y sus problemas)

#### A) Renta Vehicular
```
Características:
├── Costo: $5,000-$8,000 MXN/semana
├── Total anual: $260K-$416K MXN
├── Tasa implícita: 30-40% anual
├── Sin opción a compra
└── Sin construcción de patrimonio

Problemas:
❌ Más caro que un crédito
❌ No genera equity
❌ Dependencia perpetua
❌ Sin mejora crediticia
```

#### B) Tandas / Préstamos Informales
```
Características:
├── Tasa: 10-15% mensual (120-180% anual)
├── Plazos: 3-6 meses
├── Montos: $10K-$50K MXN
└── Sin garantías formales

Problemas:
❌ Tasas usurarias
❌ Montos insuficientes
❌ Riesgo de sobreendeudamiento
❌ Sin protección legal
```

#### C) Casas de Empeño
```
Características:
├── Garantía: Joyas, electrónicos
├── Tasa: 10-20% mensual
├── Plazo: 1-3 meses
└── Monto: 60-70% valor prenda

Problemas:
❌ Montos muy bajos
❌ Plazos cortos
❌ Pérdida de activos
❌ No resuelve necesidad vehicular
```

---

## 💡 Propuesta de Valor

### 1. Solución: Scoring Crediticio Alternativo

**Tesis Central:**
> "Los datos operativos (GPS, telemetría, ingresos digitales) son MEJORES predictores de pago que el historial bancario tradicional para conductores de plataformas."

### 2. Motor HASE: Nuevo Paradigma de Evaluación

```python
# Scoring Tradicional Bancario
score_bancario = f(
    historial_creditos,    # No tienen
    antiguedad_laboral,    # Informal
    ingresos_comprobables, # Variables
    avalistas              # No tienen
) → RECHAZADO

# Scoring HASE (Conductores del Mundo)
score_hase = f(
    # Telemetría (50 features)
    dias_trabajados_30d,
    horas_activas_promedio,
    driver_score,
    km_recorridos,
    eventos_riesgo,

    # Financiero (30 features)
    ingresos_mensuales_conekta,
    estabilidad_ingresos,
    gastos_operativos,
    capacidad_pago,

    # Social (40 features)
    verificacion_kyc_metamap,
    referencias_laborales,
    tiempo_conductor,
    plataformas_activas,

    # Buró (30 features - opcional)
    historial_crediticio
) → Score 0-100 + SINOSURE Tier (AAA/AA/A/B)
```

### 3. Ventajas Competitivas

| Aspecto | Banca Tradicional | Conductores del Mundo |
|---------|-------------------|------------------------|
| **Evaluación** | Historial bancario | Datos operativos en tiempo real |
| **Decisión** | 7-15 días | 24-48 horas |
| **Enganche** | 30-40% | 10-20% |
| **Tasa** | 18-25% anual | 14-18% anual |
| **Requisitos** | Nómina + avalista | GPS + KYC biométrico |
| **Flexibilidad** | 0 pausas | 2-3 pausas/año |
| **Seguro crédito** | No | Sí (SINOSURE $10M USD) |

---

## 📈 Oportunidad de Negocio

### 1. Ventana de Mercado

```
Tendencias Favorables:
├── Crecimiento plataformas digitales (+15% anual)
├── Digitalización pagos México (+25% anual)
├── Open Banking (ley fintech 2024)
├── Madurez GPS/telemetría vehicular
├── Acceso APIs KYC biométrico
└── Infraestructura cloud escalable

Timing:
✅ Mercado maduro (4.2M conductores)
✅ Tecnología disponible (Geotab, Conekta, Metamap)
✅ Regulación favorable (fintech sandbox)
✅ Competencia limitada (blue ocean)
```

### 2. Modelo de Ingresos

```
Fuentes de Ingreso:
├── Intereses crediticios (14-18% anual)
├── Comisiones apertura (2-3%)
├── Comisiones administración (1% anual)
├── Seguros opcionales (5-8% anual)
└── Servicios adicionales (mantenimiento, gasolina)

Proyección Año 1:
5,000 créditos × $200K promedio × 16% tasa × 50% año = $8M MXN ingresos
```

### 3. Unit Economics (Crédito Típico)

```yaml
Crédito Típico:
  Monto: $200,000 MXN
  Plazo: 36 meses
  Tasa: 16% anual
  Pago mensual: $7,056 MXN

Ingresos (3 años):
  Intereses: $54,016 MXN
  Comisión apertura: $6,000 MXN (3%)
  Total ingresos: $60,016 MXN

Costos:
  Costo capital: $200K × 10% × 3 años = $60,000 MXN
  SINOSURE (1.5% anual): $9,000 MXN
  Operación: $5,000 MXN
  Default (5% provisión): $10,000 MXN
  Total costos: $84,000 MXN

Margen Bruto: $60,016 - $24,000 (interés costo capital) = $36,016 MXN
ROE: 18% anual
```

---

## 🎯 Conclusiones del Diagnóstico

### ✅ Problema Validado
1. **4.2M conductores** con necesidad real
2. **72% sin vehículo propio** (3M mercado)
3. **85% rechazados** por banca tradicional
4. Alternativas actuales **30-40% tasa** (rentas)

### ✅ Solución Diferenciada
1. **Scoring alternativo** con datos operativos
2. **Decisión rápida** (24-48 hrs vs 7-15 días)
3. **Tasa competitiva** (14-18% vs 30-40%)
4. **Flexibilidad** (pausas de pago)

### ✅ Mercado Atractivo
1. **$60B MXN** mercado serviceable
2. **$100M MXN** objetivo año 1
3. **18% ROE** unit economics
4. **Blue ocean** (poca competencia)

---

## 🚀 Siguiente Fase

**→ CORE_FASE2_ARQUITECTURA.md**
- Diseño técnico del sistema
- Stack tecnológico
- Arquitectura de microservicios
- Infraestructura cloud
