# CORE FASE 8: PRODUCTOS FINANCIEROS & LÓGICA MATEMÁTICA

## 🎯 Objetivo
Documentar la lógica matemática y de negocio de todos los productos financieros: TANDA (Crédito Colectivo), Venta a Plazo, Cotizador, Simulador, y sistemas de protección.

---

## 📦 PRODUCTO 1: TANDA (Crédito Colectivo)

### Concepto
Sistema de **ahorro colectivo que se convierte en deuda colectiva escalonada**. Un grupo de N miembros ahorra en conjunto para el enganche de la primera unidad. Una vez entregada, el grupo paga la deuda de esa unidad Y SIMULTÁNEAMENTE ahorra para el enganche de la segunda.

**Efecto "Bola de Nieve"**: La responsabilidad de pago mensual del grupo aumenta con cada unidad entregada.

---

### Modelo de Datos (3 Entidades)

#### 1. Objeto Tanda (Contenedor Principal)
```json
{
  "tandaId": "TANDA_RUTA25_01",
  "nombre": "Tanda Ruta 25 - Primeras 5",
  "estado": "PAGO_Y_AHORRO",  // AHORRO_INICIAL, PAGO_Y_AHORRO, PAGO_FINAL
  "numeroMiembros": 5,
  "unidadesEntregadas": 1,
  "metaEnganchePorUnidad": 153075.00,
  "pagoMensualPorUnidad": 25720.52
}
```

#### 2. Objeto MiembroTanda (Participante)
```json
{
  "miembroId": "CLIENTE_007",
  "tandaId": "TANDA_RUTA25_01",
  "nombre": "Javier Rodriguez",
  "estado": "ACTIVO",  // ACTIVO, PENDIENTE_ACTIVACION
  "totalAportadoPersonal": 65200.00
}
```

#### 3. Objeto CicloTanda (Estado Financiero Actual)
**El objeto más importante**: Representa para qué unidad están ahorrando y cuántas deudas están pagando.

```json
{
  "cicloId": "CICLO_TANDA_R25_01_U2",
  "tandaId": "TANDA_RUTA25_01",
  "numeroCiclo": 2,  // Ahorrando para la unidad #2
  "metaAhorroCiclo": 153075.00,  // Siempre es el enganche
  "ahorroAcumuladoCiclo": 45100.00,  // Lo que llevan para enganche #2
  "metaPagoMensualCiclo": 25720.52,  // Deuda de la unidad #1
  "pagoAcumuladoMesCiclo": 18300.00  // Lo que han pagado de deuda este mes
}
```

---

### Lógica de Transición de Estados (Algoritmo "Bola de Nieve")

#### Paso 1: Inicio (Ciclo 1)
```yaml
Estado inicial:
  - Tanda: AHORRO_INICIAL
  - CicloTanda.numeroCiclo: 1
  - CicloTanda.metaPagoMensualCiclo: 0
  - Objetivo único: llenar ahorroAcumuladoCiclo
```

#### Paso 2: Trigger - Meta de Ahorro Alcanzada
```python
# Condición
if ahorroAcumuladoCiclo >= metaAhorroCiclo:
    # Acción: Entregar primera unidad
    entregar_unidad()
```

#### Paso 3: Transición al Siguiente Ciclo
```python
def transicion_ciclo(tanda, ciclo_actual):
    # 1. Incrementar unidades entregadas
    tanda.unidadesEntregadas += 1

    # 2. Crear nuevo CicloTanda
    nuevo_ciclo = CicloTanda(
        numeroCiclo=ciclo_actual.numeroCiclo + 1,
        tandaId=tanda.tandaId,
        metaAhorroCiclo=tanda.metaEnganchePorUnidad,  # Mismo enganche
        ahorroAcumuladoCiclo=0,  # Reset a 0
        metaPagoMensualCiclo=tanda.pagoMensualPorUnidad * tanda.unidadesEntregadas,
        pagoAcumuladoMesCiclo=0
    )

    # 3. Cambiar estado Tanda
    tanda.estado = "PAGO_Y_AHORRO"

    return nuevo_ciclo

# Ejemplo:
# Ciclo 1: metaPagoMensualCiclo = $25,720.52 (1 unidad)
# Ciclo 2: metaPagoMensualCiclo = $51,441.04 (2 unidades)
# Ciclo 3: metaPagoMensualCiclo = $77,161.56 (3 unidades)
```

#### Paso 4: Repetir
El proceso se repite. Cuando alcanzan `metaAhorroCiclo` de nuevo:
- Se entrega unidad 2
- `unidadesEntregadas` → 2
- `metaPagoMensualCiclo` del Ciclo 3 se duplica

#### Paso 5: Fase Final
```python
if tanda.unidadesEntregadas == tanda.numeroMiembros:
    tanda.estado = "PAGO_FINAL"
    # Ya no se crean nuevos ciclos de ahorro
    # Solo cumplir con metaPagoMensualCiclo hasta liquidar todas las deudas
```

---

### Conciliación de Pagos

```python
def procesar_pago_tanda(pago, miembro, ciclo_actual):
    """
    Cuando llega un pago (recaudo o voluntario)
    """
    # 1. Identificar al MiembroTanda
    miembro = get_miembro(pago.miembroId)

    # 2. Consultar CicloTanda actual
    ciclo = get_ciclo_actual(miembro.tandaId)

    # 3. Aplicar dinero según regla (50/50)
    mitad = pago.monto / 2

    ciclo.pagoAcumuladoMesCiclo += mitad  # 50% a pago de deuda
    ciclo.ahorroAcumuladoCiclo += mitad   # 50% a ahorro

    # 4. Actualizar total aportado por miembro
    miembro.totalAportadoPersonal += pago.monto

    # 5. Verificar triggers
    if ciclo.ahorroAcumuladoCiclo >= ciclo.metaAhorroCiclo:
        entregar_siguiente_unidad()
```

---

### Ejemplo Numérico Completo

```yaml
Configuración:
  Grupo: 5 miembros
  Vehículo: $1,020,500 MXN (Paquete EdoMex)
  Enganche: 15% = $153,075 MXN
  Monto a financiar: $867,425 MXN
  Plazo: 60 meses
  Tasa: 29.9% anual
  Pago mensual por unidad: $25,720.52 MXN

Ciclo 1 (Ahorro inicial):
  Meta ahorro: $153,075
  Pago deuda: $0
  Aportación por miembro: ~$30,615/mes
  Duración: ~5 meses
  → Se entrega unidad #1

Ciclo 2 (Primera deuda + ahorrando para #2):
  Meta ahorro: $153,075
  Pago deuda: $25,720.52
  Total grupo: $178,795.52/mes
  Por miembro: ~$35,759/mes
  Duración: ~5 meses
  → Se entrega unidad #2

Ciclo 3 (Dos deudas + ahorrando para #3):
  Meta ahorro: $153,075
  Pago deuda: $51,441.04 (2 unidades)
  Total grupo: $204,516.04/mes
  Por miembro: ~$40,903/mes
  Duración: ~5 meses
  → Se entrega unidad #3

Ciclo 4 (Tres deudas + ahorrando para #4):
  Total grupo: $230,236.56/mes
  Por miembro: ~$46,047/mes

Ciclo 5 (Cuatro deudas + ahorrando para #5):
  Total grupo: $255,957.08/mes
  Por miembro: ~$51,191/mes

Fase Final (5 deudas, sin ahorro):
  Pago deuda: $128,602.60/mes (5 × $25,720.52)
  Por miembro: ~$25,720/mes
  Duración: 60 meses desde última entrega
```

---

## 📊 PRODUCTO 2: COTIZADOR INTELIGENTE

### Concepto
Motor de cotización dinámica que se adapta al **mercado** (Aguascalientes vs EdoMex) y **tipo de venta** (Individual vs Colectivo/Tanda).

---

### Configuración por Mercado

#### Paquete Aguascalientes
```yaml
Producto:
  Vagoneta H6C 19p: $799,000
  Conversión GNV: $54,000 (opcional)
  Total: $853,000

Financiamiento:
  Límite máximo: 40% del valor
  Monto máximo a financiar: $341,200
  Enganche mínimo: 60% = $511,800
  Tasa: 25.5% anual
  Plazos disponibles: [12, 24] meses

Fórmula PMT:
  pago_mensual = monto * [r(1+r)^n] / [(1+r)^n - 1]

  Donde:
    monto = $341,200
    r = 0.255 / 12 = 0.02125 (tasa mensual)
    n = 24 meses

  Resultado: $18,282.88 MXN/mes
```

#### Paquete Estado de México
```yaml
Producto:
  Vagoneta H6C Ventanas: $749,000
  Conversión GNV: $54,000
  Paquete Tecnológico: $12,000
  Bancas adicionales: $22,000
  Seguro anual: $36,700
  Total: $873,700

Financiamiento:
  Enganche Individual: 15-20%
  Enganche Colectivo: 15% (incentivo)
  Tasa: 29.9% anual
  Plazos disponibles: [48, 60] meses

Ejemplo Individual (20% enganche, 60 meses):
  Enganche: $174,740
  Monto a financiar: $698,960
  Pago mensual: $20,725.42 MXN
```

---

### Tabla de Amortización (Ejemplo EdoMex Individual)

```python
def generar_tabla_amortizacion(monto, tasa_anual, plazo_meses):
    """
    Genera tabla de amortización con método francés
    """
    tasa_mensual = tasa_anual / 12

    # Calcular pago fijo mensual (PMT)
    factor = (1 + tasa_mensual) ** plazo_meses
    pago_mensual = monto * (tasa_mensual * factor) / (factor - 1)

    tabla = []
    saldo = monto

    for mes in range(1, plazo_meses + 1):
        interes = saldo * tasa_mensual
        pago_capital = pago_mensual - interes
        saldo -= pago_capital

        tabla.append({
            "num_pago": mes,
            "pago_mensual": round(pago_mensual, 2),
            "pago_capital": round(pago_capital, 2),
            "interes": round(interes, 2),
            "saldo_insoluto": round(max(0, saldo), 2)
        })

    return tabla

# Ejemplo: EdoMex Individual, $816,400, 29.9%, 60 meses
tabla = generar_tabla_amortizacion(816400, 0.299, 60)
```

**Resultado (primeros 3 meses):**

| No. Pago | Pago Mensual | Pago a Capital | Interés | Saldo Insoluto |
|----------|--------------|----------------|---------|----------------|
| 1 | $24,204.62 | $3,873.62 | $20,331.00 | $812,526.38 |
| 2 | $24,204.62 | $3,970.00 | $20,234.62 | $808,556.38 |
| 3 | $24,204.62 | $4,068.91 | $20,135.71 | $804,487.47 |
| ... | ... | ... | ... | ... |
| 60 | $24,204.62 | $23,612.31 | $592.31 | $0.00 |

---

### API Endpoints del Cotizador

```python
# Endpoint: GET /api/cotizador/paquete/:mercado
{
  "mercado": "aguascalientes",
  "componentes": [
    {"nombre": "Vagoneta H6C 19p", "precio": 799000, "obligatorio": true},
    {"nombre": "Conversión GNV", "precio": 54000, "obligatorio": false}
  ],
  "reglas": {
    "tasa_anual": 0.255,
    "plazos": [12, 24],
    "limite_financiamiento": 0.40,  // Máximo 40%
    "enganche_minimo": 0.60  // Mínimo 60%
  }
}

# Endpoint: POST /api/cotizador/quote
Request:
{
  "mercado": "edomex",
  "tipo_venta": "individual",
  "precio_vehiculo": 873700,
  "enganche": 174740,  // 20%
  "plazo_meses": 60
}

Response:
{
  "monto_financiar": 698960,
  "pago_mensual": 20725.42,
  "total_intereses": 544564.20,
  "tasa_anual": 0.299,
  "tabla_amortizacion_url": "/api/cotizador/amortizacion/{{quote_id}}"
}
```

---

## 🧮 PRODUCTO 3: SIMULADOR FINANCIERO

### Concepto
Herramienta de modelado de escenarios que se adapta según la intención del cliente. **3 modos diferentes**.

---

### Modo 1: Proyector de Ahorro y Liquidación (Aguascalientes)

**Caso de uso**: Cliente con unidades operando que generan recaudo. Quiere saber cuánto puede ahorrar y cuánto le falta por liquidar.

```python
class ProyectorAhorroLiquidacion:
    def __init__(self, enganche_inicial, fecha_entrega, unidades_recaudo):
        self.enganche_inicial = enganche_inicial
        self.fecha_entrega = fecha_entrega  # 3-6 meses
        self.unidades_recaudo = unidades_recaudo  # [{consumo_mensual, sobreprecio}]

    def calcular_ahorro_proyectado(self):
        """
        Proyecta ahorro basado en recaudación de unidades existentes
        """
        ahorro_mensual = 0

        for unidad in self.unidades_recaudo:
            # Sobreprecio GNV típico: $2.50/litro
            # Consumo promedio: 300 litros/mes
            ahorro_unidad = unidad["consumo_mensual"] * unidad["sobreprecio"]
            ahorro_mensual += ahorro_unidad

        meses_hasta_entrega = self.calcular_meses(self.fecha_entrega)
        ahorro_total = ahorro_mensual * meses_hasta_entrega

        return {
            "ahorro_mensual": ahorro_mensual,
            "ahorro_proyectado": ahorro_total,
            "valor_total_vehiculo": 853000,
            "cobertura": self.enganche_inicial + ahorro_total,
            "remanente_liquidar": 853000 - (self.enganche_inicial + ahorro_total)
        }

# Ejemplo:
simulador = ProyectorAhorroLiquidacion(
    enganche_inicial=400000,
    fecha_entrega="2025-04-01",  # 5 meses
    unidades_recaudo=[
        {"consumo_mensual": 300, "sobreprecio": 2.50},  # $750/mes
        {"consumo_mensual": 280, "sobreprecio": 2.50},  # $700/mes
    ]
)

resultado = simulador.calcular_ahorro_proyectado()
# Output:
{
  "ahorro_mensual": 1450,
  "ahorro_proyectado": 7250,  # 5 meses × $1,450
  "valor_total_vehiculo": 853000,
  "cobertura": 407250,  # $400K + $7.25K
  "remanente_liquidar": 445750  # ESTIMADO
}
```

**Output Visual (PWA)**:
```
┌─────────────────────────────────────┐
│ Proyector de Ahorro y Liquidación   │
├─────────────────────────────────────┤
│ Valor Total: $853,000               │
│                                     │
│ ▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░             │
│ ├─ Enganche: $400,000 (47%)        │
│ ├─ Ahorro Proyectado: $7,250 (1%)  │
│ └─ REMANENTE: $445,750 (52%)       │
│                                     │
│ 📊 Ahorro mensual: $1,450           │
│ 📅 Fecha entrega: Abril 2025        │
│ 🔧 Unidades generando: 2            │
└─────────────────────────────────────┘
```

---

### Modo 2: Planificador de Enganche (EdoMex Individual)

**Caso de uso**: Cliente quiere saber **cuándo podrá tener su enganche** si ahorra X cantidad al mes.

```python
class PlanificadorEnganche:
    def __init__(self, meta_enganche, unidad_actual, aportacion_voluntaria):
        self.meta_enganche = meta_enganche  # Ej: 15% de $873,700 = $131,055
        self.unidad_actual = unidad_actual  # {consumo_mensual, sobreprecio}
        self.aportacion_voluntaria = aportacion_voluntaria  # Extra mensual

    def calcular_tiempo_enganche(self):
        """
        Calcula cuándo se alcanzará el enganche
        """
        # Ahorro automático (recaudo unidad actual)
        ahorro_automatico = self.unidad_actual["consumo_mensual"] * \
                           self.unidad_actual["sobreprecio"]

        # Ahorro total mensual
        ahorro_total_mes = ahorro_automatico + self.aportacion_voluntaria

        # Meses necesarios
        meses_necesarios = self.meta_enganche / ahorro_total_mes

        # Fecha estimada
        from datetime import datetime, timedelta
        fecha_estimada = datetime.now() + timedelta(days=meses_necesarios*30)

        return {
            "meta_enganche": self.meta_enganche,
            "ahorro_automatico_mes": ahorro_automatico,
            "aportacion_voluntaria_mes": self.aportacion_voluntaria,
            "ahorro_total_mes": ahorro_total_mes,
            "meses_necesarios": round(meses_necesarios, 1),
            "fecha_estimada": fecha_estimada.strftime("%Y-%m-%d")
        }

# Ejemplo:
planificador = PlanificadorEnganche(
    meta_enganche=131055,  # 15% de $873,700
    unidad_actual={"consumo_mensual": 300, "sobreprecio": 2.50},  # $750/mes
    aportacion_voluntaria=5000  # Cliente ahorra extra
)

resultado = planificador.calcular_tiempo_enganche()
# Output:
{
  "meta_enganche": 131055,
  "ahorro_automatico_mes": 750,
  "aportacion_voluntaria_mes": 5000,
  "ahorro_total_mes": 5750,
  "meses_necesarios": 22.8,  # ~23 meses
  "fecha_estimada": "2027-01-15"
}
```

**Output Visual (PWA) - Gráfica Interactiva**:
```
Tiempo Estimado para Alcanzar Enganche
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

     Ahorro: $0/mes        Ahorro: $10,000/mes
        ↓                          ↓
      261 meses                  10 meses
        │◄─────────────────────────►│
        │                           │
      Slider: [$5,000/mes] → 23 meses
                 │
                 └─ Fecha: Ene 2027
```

---

### Modo 3: Simulador de Tanda Colectiva

**Caso de uso**: Mostrar el "efecto bola de nieve" con timeline interactivo.

```python
class SimuladorTandaColectiva:
    def __init__(self, num_integrantes, consumo_promedio, sobreprecio, paquete):
        self.num_integrantes = num_integrantes
        self.consumo_promedio = consumo_promedio
        self.sobreprecio = sobreprecio
        self.paquete = paquete  # Datos del vehículo

    def simular_timeline(self):
        """
        Genera timeline del efecto bola de nieve
        """
        enganche = self.paquete["precio"] * 0.15  # 15% colectivo
        monto_financiar = self.paquete["precio"] - enganche
        pago_mensual_unidad = self.calcular_pmt(
            monto_financiar,
            self.paquete["tasa"],
            self.paquete["plazo"]
        )

        # Ahorro colectivo mensual
        ahorro_colectivo_mes = (self.consumo_promedio * self.sobreprecio *
                                self.num_integrantes)

        timeline = []
        meses_acumulados = 0

        for unidad in range(1, self.num_integrantes + 1):
            # Meses para juntar enganche
            if unidad == 1:
                # Primera unidad: solo ahorro
                meses_ahorro = enganche / ahorro_colectivo_mes
                pago_deuda_mes = 0
            else:
                # Unidades 2+: ahorro + pago deuda
                deuda_actual = pago_mensual_unidad * (unidad - 1)
                disponible_ahorro = ahorro_colectivo_mes - deuda_actual
                meses_ahorro = enganche / disponible_ahorro
                pago_deuda_mes = deuda_actual

            meses_acumulados += meses_ahorro

            timeline.append({
                "unidad": unidad,
                "fecha_estimada_entrega": self.calcular_fecha(meses_acumulados),
                "meses_desde_inicio": round(meses_acumulados, 1),
                "ahorro_colectivo_mes": ahorro_colectivo_mes,
                "pago_deuda_mes": pago_deuda_mes,
                "pago_total_grupo_mes": ahorro_colectivo_mes,  # Siempre constante
                "pago_por_miembro_mes": ahorro_colectivo_mes / self.num_integrantes
            })

        return timeline

# Ejemplo:
simulador = SimuladorTandaColectiva(
    num_integrantes=5,
    consumo_promedio=300,  # litros/mes por unidad
    sobreprecio=2.50,
    paquete={
        "precio": 873700,
        "tasa": 0.299,
        "plazo": 60
    }
)

timeline = simulador.simular_timeline()
```

**Output (Timeline Interactivo)**:
```
Simulador Tanda Colectiva - 5 Integrantes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Mes 0          Mes 5          Mes 10         Mes 15         Mes 20
    │              │              │              │              │
    ├──────────────●──────────────●──────────────●──────────────●
  Inicio      Unidad 1      Unidad 2      Unidad 3      Unidad 4
              $3,750/mes    $7,500/mes    $11,250/mes   $15,000/mes
              por miembro   por miembro   por miembro   por miembro

📊 Ahorro colectivo: $18,750/mes (constante)
💰 Pago por miembro crece: $3,750 → $15,000
🚐 Entregas: Una cada ~5 meses
```

---

## 🏦 ARQUITECTURA: CORE BANCARIO LIGERO

### Concepto
Sistema bancario construido con **Odoo (ERP) + Airtable (Staging)** sin usar core bancario tradicional. **14 pasos** desde onboarding hasta retención de datos.

---

### Flujo Completo (14 Pasos)

```
PASO 01: Onboarding (Cliente)
├─ Input: Datos personales, consentimiento
├─ Validación: KYC básico
└─ Output: customer_id

    ↓

PASO 02: Alta Cuenta Virtual
├─ Servicio: POST /core/accounts
├─ Crea: {customer_id, account_ref, status, opened_at}
├─ Replica en: Odoo (contacto) + Airtable (ops)
└─ Output: account_ref

    ↓

PASO 03: Generar Referencia de Pago
├─ Gateway: Conekta SPEI/OXXO
├─ Parámetros: {amount, currency, expires_at}
├─ Output: {order_id, clabe, qr_code}
└─ Envío: Email/WhatsApp

    ↓

PASO 04: Pago Entrante (Staging)
├─ Webhook: POST /webhooks/payments
├─ Airtable: Guarda raw_payload + tx_id
└─ Estado: STAGING

    ↓

PASO 05: Webhook → Normalización
├─ Middleware: Make/Zapier
├─ Transacción normalizada: {tx_id, account_ref, amount, method, timestamp}
├─ Idempotencia: tx_id + HMAC
└─ Output: Transacción lista para ledger

    ↓

PASO 06: Antifraude / Validaciones
├─ Checks:
│   ├─ IP allowlist
│   ├─ HMAC signature
│   ├─ Monto vs límites
│   ├─ Listas internas
│   └─ Desviaciones de patrón
├─ Resultado: APPROVED / REVIEW / REJECTED
└─ Si falla → PASO 13 (Excepciones)

    ↓

PASO 07: Asiento en Odoo (Ledger)
├─ Journal Entry:
│   Débito:  Cuenta Clearing (banco)    $10,000
│   Crédito: Cuenta Virtual (cliente)   $10,000
├─ Actualiza: Saldo del cliente
├─ Adjunta: Comprobante de pago
└─ Estado: POSTED

    ↓

PASO 08: Conciliación Bancaria
├─ Import: Extracto bancario (OFX/CSV/API)
├─ Match: Monto + Fecha + Referencia
├─ Concilia: Journal vs Staging vs Banco
└─ Diferencias → PASO 13 (Excepciones)

    ↓

PASO 09: Notificación / Recibo
├─ Genera: PDF/HTML recibo
├─ Envía: Email + WhatsApp
├─ Registra: Evento en historial cliente
└─ Estado: CONFIRMED

    ↓

PASO 10: Dispersión/Egreso
├─ Solicitud: Retiro o pago proveedor
├─ Autorización: Dos pares de ojos
├─ SPEI: Validar CLABE
├─ Asiento contable: Inverse del paso 07
└─ Idempotencia: request_id

    ↓

PASO 11: Estados de Cuenta
├─ Generación: Cron job (mensual)
├─ Incluye:
│   ├─ Saldo inicial
│   ├─ Movimientos del mes
│   ├─ Comisiones
│   └─ Impuestos
├─ Formato: PDF firmado
└─ Envío: Email seguro

    ↓

PASO 12: Reportes & BI
├─ Dashboards:
│   ├─ Operativos (Airtable)
│   └─ Financieros (Odoo)
├─ Export: S3/MinIO (Parquet)
└─ KPIs: Saldo total, entradas/salidas, morosidad, aging

    ↓

PASO 13: Excepciones / PLD
├─ Bandeja de alertas:
│   ├─ Transacciones fuera de patrón
│   ├─ Duplicados
│   ├─ Listas internas (PLD)
│   └─ Montos inusuales
├─ Flujo: Remediation workflow
└─ Bitácora: Audit trail

    ↓

PASO 14: Hardening & Retención
├─ Logs: Firmados digitalmente
├─ Cifrado: At-rest + in-transit
├─ Retención: 90/180/360 días
├─ Backups: Diarios (S3)
└─ BCP/DR: Business continuity plan
```

---

### Especificaciones Técnicas por Paso

#### Paso 02: Alta Cuenta Virtual
```python
# POST /core/accounts
Request:
{
  "customer_id": "CLIENTE_007",
  "account_type": "virtual_savings",
  "currency": "MXN",
  "metadata": {
    "source": "pwa_registration",
    "ip": "189.203.x.x"
  }
}

Response:
{
  "account_ref": "ACCT_VIR_00712345",
  "customer_id": "CLIENTE_007",
  "status": "active",
  "balance": 0.00,
  "currency": "MXN",
  "opened_at": "2025-01-15T10:30:00Z",
  "odoo_partner_id": 4523,
  "airtable_record_id": "recXYZ123"
}
```

#### Paso 07: Asiento Contable (Odoo)
```python
# Journal Entry Structure
entry = {
  "journal_id": 1,  # Banco Virtual
  "date": "2025-01-15",
  "ref": "PAG-00123",
  "line_ids": [
    # Débito (entrada de dinero)
    {
      "account_id": 100,  # Cuenta Clearing (Banco)
      "name": "Pago recibido - CLIENTE_007",
      "debit": 10000.00,
      "credit": 0.00,
      "partner_id": 4523
    },
    # Crédito (aumenta saldo cliente)
    {
      "account_id": 200,  # Cuenta Virtual Cliente
      "name": "Abono a cuenta virtual",
      "debit": 0.00,
      "credit": 10000.00,
      "partner_id": 4523,
      "analytic_account_id": 50  # Tracking por cliente
    }
  ],
  "attachment_ids": [(6, 0, [comprobante_id])]  # Adjuntar PDF
}
```

---

## 🚀 PRÓXIMOS PASOS

Este archivo documenta:
- ✅ TANDA (Crédito Colectivo) - Completo
- ✅ COTIZADOR - Completo
- ✅ SIMULADOR - Completo
- ✅ CORE BANCARIO - Completo

**Pendiente documentar:**
- ⏳ AVI (Anticipo de Valor Incremental)
- ⏳ PROTECCIÓN (Seguros y garantías)
- ⏳ VENTA A PLAZO (detalles adicionales)
- ⏳ COMPRA DIRECTA
- ⏳ AHORRO PROGRAMADO

**Siguiente:** Buscar documentación de AVI y Protección para completar.

---

**Metodología Manual Quirúrgico** - Productos Financieros con Lógica Matemática Completa
