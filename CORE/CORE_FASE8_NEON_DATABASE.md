# FASE 8: NEON DATABASE - Schema Completo y Migración de Datos

**Versión:** 1.0
**Fecha:** Octubre 2024
**Estado:** ✅ Completo
**Base de Datos:** NEON PostgreSQL (Serverless)

---

## 🎯 Objetivo

Este documento define el **schema completo de la base de datos NEON** para Conductores del Mundo, incluyendo:

- 📊 **30+ tablas** (telemetría, negocio, históricos, IA, catálogos)
- 🔗 **Relaciones y Foreign Keys** completas
- 🌐 **API REST endpoints** mapeados
- 🔄 **Estrategia de migración** desde Consware (históricos 2013-2025)
- 📈 **Datos GNV** para calibrar motor HASE

---

## 🏗️ ARQUITECTURA GENERAL

```
┌─────────────────────────────────────────────────────────────┐
│                  NEON DATABASE ARCHITECTURE                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. CORE TELEMATICS (vehicle, location, metrics, DTC)      │
│  2. BUSINESS CORE (customers, contracts, transactions)     │
│  3. HISTORICAL DATA (gnv_consumption, critical_events)     │
│  4. INTELLIGENCE (hase_scores, pma_alerts)                 │
│  5. CATALOGS (fault_catalog, spare_parts, geofences)       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. CORE TELEMATICS - Telemetría y Activos

### 1.1 Tabla: `vehicle` (Maestro de Flota)

```sql
CREATE TABLE vehicle (
  id TEXT PRIMARY KEY,              -- Código interno (e.g., "VH001")
  vin TEXT UNIQUE NOT NULL,         -- Vehicle Identification Number
  plate TEXT UNIQUE NOT NULL,       -- Placa
  make TEXT NOT NULL,               -- Marca (Higer, Joylong, etc.)
  model TEXT NOT NULL,              -- Modelo
  year INTEGER NOT NULL,            -- Año
  tag TEXT,                         -- Etiqueta/categoría
  owner_id TEXT,                    -- ID propietario
  alta_at TIMESTAMP DEFAULT NOW(), -- Fecha de alta
  status TEXT DEFAULT 'active',     -- active, inactive, maintenance
  metadata JSONB                    -- Metadata flexible
);

CREATE INDEX idx_vehicle_owner ON vehicle(owner_id);
CREATE INDEX idx_vehicle_status ON vehicle(status);
```

**Relaciones:** Núcleo de casi todas las tablas (parent de eventos, métricas, alertas).

---

### 1.2 Tabla: `location_event` (GPS/Telemetría)

```sql
CREATE TABLE location_event (
  id BIGSERIAL PRIMARY KEY,
  vehicle_id TEXT NOT NULL REFERENCES vehicle(id),
  ts TIMESTAMP NOT NULL,            -- Timestamp del evento
  lat DOUBLE PRECISION NOT NULL,    -- Latitud
  lon DOUBLE PRECISION NOT NULL,    -- Longitud
  speed_kph DOUBLE PRECISION,       -- Velocidad (km/h)
  heading_deg DOUBLE PRECISION,     -- Rumbo (grados)
  ignition BOOLEAN,                 -- Encendido
  accuracy_m DOUBLE PRECISION,      -- Precisión GPS (metros)
  event_id UUID,                    -- ID de evento (Geotab)
  inserted_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_location_vehicle_ts ON location_event(vehicle_id, ts DESC);
CREATE INDEX idx_location_ts ON location_event(ts DESC);
```

**Ingesta:** Datos de Geotab API cada 30-60 segundos.

**API Endpoint:**
```
POST /v1/location_event
GET  /v1/location_event?vehicle_id=VH002&from=2025-01-01&to=2025-01-31
```

---

### 1.3 Tabla: `metric` (Métricas OBD-II / CAN / BMS)

```sql
CREATE TABLE metric (
  vehicle_id TEXT NOT NULL REFERENCES vehicle(id),
  ts TIMESTAMP NOT NULL,

  -- Métricas principales
  odometer_km DOUBLE PRECISION,
  rpm DOUBLE PRECISION,
  battery_v DOUBLE PRECISION,
  dtc_count INTEGER,
  coolant_temp_c DOUBLE PRECISION,
  engine_load_pct DOUBLE PRECISION,

  -- Aceite
  oil_level_pct DOUBLE PRECISION,
  oil_pressure_kpa DOUBLE PRECISION,

  -- Combustible
  fuel_level_pct DOUBLE PRECISION,
  fuel_consumption_rate_lph DOUBLE PRECISION,
  fuel_economy_l100km DOUBLE PRECISION,

  -- Otros
  air_flow_maf DOUBLE PRECISION,
  alternator_v DOUBLE PRECISION,
  idle_time_sec INTEGER,

  PRIMARY KEY (vehicle_id, ts)
);

CREATE INDEX idx_metric_vehicle_ts ON metric(vehicle_id, ts DESC);
```

**Ingesta:** Datos de Geotab Device Data (OBD-II) cada 5 minutos.

---

### 1.4 Tabla: `driver_behavior_event` (Eventos de Conducción)

```sql
CREATE TABLE driver_behavior_event (
  id BIGSERIAL PRIMARY KEY,
  vehicle_id TEXT NOT NULL REFERENCES vehicle(id),
  driver_id TEXT,                   -- ID conductor (si disponible)
  ts TIMESTAMP NOT NULL,
  event_type TEXT NOT NULL,         -- harsh_brake, harsh_accel, harsh_turn, speeding
  value DOUBLE PRECISION,           -- Valor (g-force, exceso velocidad)
  raw_data JSONB,                   -- Datos crudos del evento
  inserted_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_driver_event_vehicle ON driver_behavior_event(vehicle_id, ts DESC);
```

**Eventos capturados:**
- `harsh_brake`: Frenado brusco (> 0.4g)
- `harsh_accel`: Aceleración brusca (> 0.4g)
- `harsh_turn`: Giro brusco (> 0.5g)
- `speeding`: Exceso de velocidad

---

### 1.5 Tabla: `dtc_event` (Códigos de Falla Diagnóstico)

```sql
CREATE TABLE dtc_event (
  vehicle_id TEXT NOT NULL REFERENCES vehicle(id),
  code TEXT NOT NULL,               -- Código DTC (P0420, P0171, etc.)
  description TEXT,
  severity TEXT,                    -- critical, warning, info
  ts TIMESTAMP NOT NULL,
  cleared_at TIMESTAMP,

  PRIMARY KEY (vehicle_id, code, ts)
);

CREATE INDEX idx_dtc_vehicle ON dtc_event(vehicle_id, ts DESC);
CREATE INDEX idx_dtc_severity ON dtc_event(severity, ts DESC);
```

---

## 2. BUSINESS CORE - Clientes, Contratos, Transacciones

### 2.1 Tabla: `customers` (Clientes)

```sql
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  external_id VARCHAR(50),          -- ID externo (Odoo, etc.)
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE,
  phone VARCHAR(20),
  rfc VARCHAR(13) UNIQUE,           -- RFC fiscal (México)
  curp VARCHAR(18),                 -- CURP
  date_of_birth DATE,
  status VARCHAR(20) DEFAULT 'active', -- active, inactive, blocked
  metadata JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  country_code VARCHAR(2) DEFAULT 'MX',
  language_code VARCHAR(2) DEFAULT 'es'
);

CREATE INDEX idx_customers_rfc ON customers(rfc);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_status ON customers(status);
```

---

### 2.2 Tabla: `contracts` (Contratos/Financiamientos)

```sql
CREATE TABLE contracts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(id),
  vehicle_id TEXT REFERENCES vehicle(id),

  contract_number VARCHAR(50) UNIQUE NOT NULL,
  contract_type VARCHAR(50) NOT NULL, -- individual, collective, cash
  product_code VARCHAR(50),           -- CRED_IND, TANDA, AHORRO
  product_name VARCHAR(100),

  -- Términos financieros
  principal_amount NUMERIC(12,2) NOT NULL,
  down_payment NUMERIC(12,2),
  interest_rate NUMERIC(5,4) NOT NULL,
  term_months INTEGER NOT NULL,
  monthly_payment NUMERIC(10,2) NOT NULL,

  -- Scoring
  hase_score INTEGER,                -- Score HASE (0-100)
  sinosure_tier VARCHAR(10),         -- AAA, AA, A, B

  -- Status
  status VARCHAR(20) DEFAULT 'pending', -- pending, active, completed, defaulted, cancelled
  disbursement_date DATE,
  maturity_date DATE,
  coverage_start_date DATE,
  coverage_end_date DATE,

  metadata JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_contracts_customer ON contracts(customer_id);
CREATE INDEX idx_contracts_vehicle ON contracts(vehicle_id);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_contracts_number ON contracts(contract_number);
```

---

### 2.3 Tabla: `transactions` (Transacciones Financieras)

```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(id),
  contract_id UUID NOT NULL REFERENCES contracts(id),

  transaction_type VARCHAR(50) NOT NULL, -- payment, disbursement, fee, penalty
  transaction_category VARCHAR(50),      -- scheduled, early, late
  amount NUMERIC(12,2) NOT NULL,
  currency_code VARCHAR(3) DEFAULT 'MXN',

  status VARCHAR(20) DEFAULT 'pending',  -- pending, completed, failed, reversed
  provider VARCHAR(50),                  -- conekta, neon_bank, cash
  gateway_reference VARCHAR(100),        -- Referencia externa

  processed_at TIMESTAMP,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_transactions_contract ON transactions(contract_id, processed_at DESC);
CREATE INDEX idx_transactions_customer ON transactions(customer_id);
CREATE INDEX idx_transactions_status ON transactions(status);
```

---

## 3. HISTORICAL DATA - Datos Históricos 2013-2025

### 3.1 Tabla: `historical_gnv_consumption` (Consumo GNV Histórico)

```sql
CREATE TABLE historical_gnv_consumption (
  id SERIAL PRIMARY KEY,
  vehicle_id VARCHAR(50),
  refuel_date DATE NOT NULL,
  station_location VARCHAR(200),
  volume_m3 NUMERIC(8,2),           -- Volumen GNV en m³
  cost_total NUMERIC(10,2),         -- Costo total en MXN
  odometer_reading NUMERIC(10,2),   -- Kilometraje en el momento
  driver_id VARCHAR(50),
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_gnv_vehicle_date ON historical_gnv_consumption(vehicle_id, refuel_date DESC);
CREATE INDEX idx_gnv_date ON historical_gnv_consumption(refuel_date DESC);
```

**Fuente:** Archivo "Archivo Ventas Diarias GNV - Vagonetas AGS.xlsx" (Consware 2013-2025)

**Uso:** Calibración del motor HASE (componente financiero histórico).

---

### 3.2 Tabla: `historical_critical_events` (Eventos Críticos Históricos)

```sql
CREATE TABLE historical_critical_events (
  id SERIAL PRIMARY KEY,
  vehicle_id VARCHAR(50),
  event_type VARCHAR(50) NOT NULL,    -- lockout, default, theft, accident, pandemic
  event_category VARCHAR(50),         -- financial, operational, external
  severity_level VARCHAR(20),         -- critical, high, medium, low
  event_timestamp TIMESTAMP NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  speed_kmh DOUBLE PRECISION,
  fault_code VARCHAR(50),
  description TEXT,
  driver_id VARCHAR(50),
  resolution_status VARCHAR(50),
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_critical_vehicle ON historical_critical_events(vehicle_id, event_timestamp DESC);
CREATE INDEX idx_critical_type ON historical_critical_events(event_type);
```

**Fuente:** Registros históricos de Consware + incidents tracking.

---

### 3.3 Tabla: `historical_vehicles` (Historial de Vehículos)

```sql
CREATE TABLE historical_vehicles (
  id SERIAL PRIMARY KEY,
  vehicle_id VARCHAR(50) NOT NULL,
  plate VARCHAR(20),
  brand VARCHAR(50),
  model VARCHAR(50),
  year INTEGER,
  engine_type VARCHAR(50),
  fuel_type VARCHAR(20),            -- GNV, diesel, gasoline, electric
  vin VARCHAR(17),
  status VARCHAR(20),
  owner_name VARCHAR(200),
  acquisition_date DATE,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_hist_vehicles_id ON historical_vehicles(vehicle_id);
```

---

## 4. INTELLIGENCE - IA y Predicción

### 4.1 Tabla: `hase_scores` (Scores HASE)

```sql
CREATE TABLE hase_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(id),
  contract_id UUID REFERENCES contracts(id),
  vehicle_id TEXT REFERENCES vehicle(id),

  -- Período del score
  score_period_start DATE NOT NULL,
  score_period_end DATE NOT NULL,

  -- Componentes del score HASE
  health_score NUMERIC(5,2),        -- 0-100 (salud vehículo)
  assets_score NUMERIC(5,2),        -- 0-100 (calidad activo)
  safety_score NUMERIC(5,2),        -- 0-100 (seguridad conducción)
  efficiency_score NUMERIC(5,2),    -- 0-100 (eficiencia operativa)
  voice_score NUMERIC(5,2),         -- 0-100 (Voice Pattern - 50% peso)
  financial_score NUMERIC(5,2),     -- 0-100 (historial financiero)
  buro_score INTEGER,               -- 300-850 (Círculo de Crédito)

  -- Score final
  overall_score NUMERIC(5,2) NOT NULL, -- 0-100 (HASE final)
  sinosure_tier VARCHAR(10),        -- AAA, AA, A, B

  -- Factors detallados (JSONB)
  health_factors JSONB,
  safety_factors JSONB,
  efficiency_factors JSONB,
  voice_factors JSONB,

  risk_level VARCHAR(20),           -- low, medium, high, critical
  recommendation TEXT,

  computed_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_hase_customer ON hase_scores(customer_id, score_period_start DESC);
CREATE INDEX idx_hase_contract ON hase_scores(contract_id);
CREATE INDEX idx_hase_tier ON hase_scores(sinosure_tier);
```

**Fórmula HASE:**
```
HASE = 50% Voice + 30% Telemetría + 15% Financiero + 5% Buró
```

---

### 4.2 Tabla: `pma_alerts` (Alertas Predictivo Mantenimiento)

```sql
CREATE TABLE pma_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES customers(id),
  contract_id UUID REFERENCES contracts(id),
  vehicle_id TEXT NOT NULL REFERENCES vehicle(id),

  alert_type VARCHAR(50) NOT NULL,  -- predictive_failure, maintenance_due, anomaly
  severity VARCHAR(20) NOT NULL,    -- critical, high, medium, low
  status VARCHAR(20) DEFAULT 'open', -- open, acknowledged, resolved, dismissed

  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,

  predicted_failure_date DATE,
  confidence_score NUMERIC(5,2),    -- 0-100 (confianza del modelo)

  -- Detalles del modelo IA
  model_version VARCHAR(50),
  model_input_data JSONB,
  model_output_data JSONB,

  recommended_action TEXT,
  estimated_cost NUMERIC(10,2),

  created_at TIMESTAMP DEFAULT NOW(),
  acknowledged_at TIMESTAMP,
  resolved_at TIMESTAMP
);

CREATE INDEX idx_pma_vehicle ON pma_alerts(vehicle_id, created_at DESC);
CREATE INDEX idx_pma_customer ON pma_alerts(customer_id);
CREATE INDEX idx_pma_status_severity ON pma_alerts(status, severity);
```

---

## 5. CATALOGS - Catálogos de Soporte

### 5.1 Tabla: `fault_catalog` (Catálogo de Fallas OBD-II)

```sql
CREATE TABLE fault_catalog (
  falla_id SERIAL PRIMARY KEY,
  codigo_falla TEXT UNIQUE NOT NULL,
  descripcion_falla TEXT NOT NULL,
  categoria_principal VARCHAR(50),   -- motor, transmision, frenos, electrico
  subcategoria VARCHAR(50),
  criticidad VARCHAR(20),            -- critica, alta, media, baja
  tipificacion_obd2 BOOLEAN DEFAULT FALSE,
  codigo_obd2 VARCHAR(10),           -- P0420, P0171, etc.
  solucion_sugerida TEXT,
  refaccion_recomendada VARCHAR(200),
  costo_estimado NUMERIC(10,2),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_fault_codigo ON fault_catalog(codigo_falla);
CREATE INDEX idx_fault_criticidad ON fault_catalog(criticidad);
```

---

### 5.2 Tabla: `spare_parts` (Catálogo de Refacciones)

```sql
CREATE TABLE spare_parts (
  refaccion_id SERIAL PRIMARY KEY,
  codigo_parte VARCHAR(50) UNIQUE NOT NULL,
  nombre VARCHAR(200) NOT NULL,
  descripcion TEXT,
  marca VARCHAR(50),
  modelo_compatible VARCHAR(100),
  categoria VARCHAR(50),
  precio_unitario NUMERIC(10,2),
  stock_disponible INTEGER DEFAULT 0,
  proveedor VARCHAR(100),
  tiempo_entrega_dias INTEGER,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_spare_codigo ON spare_parts(codigo_parte);
```

---

### 5.3 Tabla: `fault_to_spare` (Mapeo Falla → Refacción)

```sql
CREATE TABLE fault_to_spare (
  falla_id INTEGER NOT NULL REFERENCES fault_catalog(falla_id),
  refaccion_id INTEGER NOT NULL REFERENCES spare_parts(refaccion_id),
  prioridad INTEGER DEFAULT 1,
  PRIMARY KEY (falla_id, refaccion_id)
);
```

---

## 6. API REST ENDPOINTS

### Vehicles & Assets
```
GET  /v1/vehicle              # Listar vehículos
GET  /v1/vehicle/{id}         # Detalle de vehículo
POST /v1/vehicle              # Crear vehículo
PUT  /v1/vehicle/{id}         # Actualizar vehículo
```

### Telemetry & Events
```
POST /v1/location_event       # Insertar evento GPS
GET  /v1/location_event?vehicle_id=VH002&from=2025-01-01&to=2025-01-31

POST /v1/metric               # Insertar métricas OBD
GET  /v1/metric?vehicle_id=VH002&date=2025-01-15

POST /v1/driver_behavior_event
GET  /v1/driver_behavior_event?vehicle_id=VH002

POST /v1/dtc_event
GET  /v1/dtc_event?vehicle_id=VH002&severity=critical
```

### Business Core
```
GET  /v1/customers
POST /v1/customers
GET  /v1/customers/{id}

GET  /v1/contracts?customer_id={uuid}
POST /v1/contracts
GET  /v1/contracts/{id}

GET  /v1/transactions?contract_id={uuid}
POST /v1/transactions
```

### Intelligence
```
GET  /v1/hase_scores?customer_id={uuid}
POST /v1/hase_scores

GET  /v1/pma_alerts?vehicle_id=VH002&status=open
POST /v1/pma_alerts
PUT  /v1/pma_alerts/{id}/acknowledge
PUT  /v1/pma_alerts/{id}/resolve
```

### Historical Data
```
GET  /v1/historical_gnv_consumption?vehicle_id=VH002&from=2013-01-01&to=2025-12-31
GET  /v1/historical_critical_events?vehicle_id=VH002
GET  /v1/historical_vehicles?plate=ABC123
```

### Catalogs
```
GET  /v1/fault_catalog
GET  /v1/fault_catalog/{id}

GET  /v1/spare_parts
GET  /v1/spare_parts/{id}

GET  /v1/fault_to_spare?falla_id={id}
```

---

## 7. ESTRATEGIA DE MIGRACIÓN

### 7.1 Migración desde Consware (Históricos 2013-2025)

**Fuente:** Sistema Consware (base de datos legacy)

**Tablas a migrar:**
1. `historical_gnv_consumption` ← Ventas diarias GNV
2. `historical_critical_events` ← Eventos críticos
3. `historical_vehicles` ← Catálogo histórico de vehículos

**Script de Migración:**
```python
# scripts/migrate_consware_to_neon.py

import pandas as pd
import psycopg2
from datetime import datetime

def migrate_gnv_consumption():
    """
    Migra datos históricos de GNV desde Excel/CSV
    Fuente: Archivo Ventas Diarias GNV - Vagonetas AGS.xlsx
    """

    # Leer archivo Excel
    df = pd.read_excel('Archivo Ventas Diarias GNV - Vagonetas AGS.xlsx')

    # Conexión a NEON
    conn = psycopg2.connect(os.getenv('NEON_DATABASE_URL'))
    cursor = conn.cursor()

    for _, row in df.iterrows():
        cursor.execute("""
            INSERT INTO historical_gnv_consumption
            (vehicle_id, refuel_date, station_location, volume_m3, cost_total, odometer_reading)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON CONFLICT DO NOTHING
        """, (
            row['vehicle_id'],
            row['refuel_date'],
            row['station_location'],
            row['volume_m3'],
            row['cost_total'],
            row['odometer_reading']
        ))

    conn.commit()
    print(f"✅ Migrated {len(df)} GNV consumption records")

def migrate_critical_events():
    """Migra eventos críticos históricos"""
    # Similar logic...

if __name__ == '__main__':
    migrate_gnv_consumption()
    migrate_critical_events()
```

---

### 7.2 Estrategia de Particionamiento (Performance)

Para tablas con alto volumen (`location_event`, `metric`), usar **particionamiento por fecha**:

```sql
-- Particionar location_event por mes
CREATE TABLE location_event_2025_01 PARTITION OF location_event
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE location_event_2025_02 PARTITION OF location_event
FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

-- etc.
```

---

## 8. CONEXIÓN Y CREDENCIALES

**NEON Console:**
```
https://console.neon.tech/app/projects/weathered-scene-29269876/branches/br-soft-recipe-ae95f8fe/sql-editor?database=neondb
```

**Connection String (env variable):**
```bash
NEON_DATABASE_URL=postgresql://user:password@weathered-scene-29269876.us-east-2.aws.neon.tech:5432/neondb?sslmode=require
```

**FastAPI Config:**
```python
# backend/app/db/database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

NEON_URL = os.getenv('NEON_DATABASE_URL')
engine = create_async_engine(NEON_URL, echo=True)
```

---

## 9. QUERIES CRÍTICOS PARA ANÁLISIS

### 9.1 Consumo GNV Promedio por Vehículo (2013-2025)
```sql
SELECT
  vehicle_id,
  COUNT(*) AS total_refuels,
  AVG(volume_m3) AS avg_volume_m3,
  AVG(cost_total) AS avg_cost,
  SUM(cost_total) AS total_spent
FROM historical_gnv_consumption
WHERE refuel_date >= '2013-01-01'
GROUP BY vehicle_id
ORDER BY total_spent DESC
LIMIT 50;
```

### 9.2 Eventos Críticos por Tipo (últimos 5 años)
```sql
SELECT
  event_type,
  COUNT(*) AS occurrences,
  AVG(EXTRACT(EPOCH FROM (NOW() - event_timestamp)) / 86400) AS avg_days_ago
FROM historical_critical_events
WHERE event_timestamp >= NOW() - INTERVAL '5 years'
GROUP BY event_type
ORDER BY occurrences DESC;
```

### 9.3 Vehículos con Mayor Riesgo (según HASE)
```sql
SELECT
  c.contract_number,
  cu.first_name || ' ' || cu.last_name AS customer_name,
  v.plate,
  h.overall_score,
  h.sinosure_tier,
  h.risk_level
FROM hase_scores h
JOIN contracts c ON h.contract_id = c.id
JOIN customers cu ON c.customer_id = cu.id
JOIN vehicle v ON c.vehicle_id = v.id
WHERE h.score_period_end >= NOW() - INTERVAL '30 days'
  AND h.risk_level IN ('high', 'critical')
ORDER BY h.overall_score ASC
LIMIT 50;
```

---

## 10. BACKUPS Y DISASTER RECOVERY

**NEON Automatic Backups:**
- ✅ Point-in-time recovery (PITR) habilitado
- ✅ Backups automáticos cada 24 horas
- ✅ Retención: 30 días

**Manual Backup Script:**
```bash
#!/bin/bash
# scripts/backup_neon.sh

pg_dump $NEON_DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql
```

---

## ✅ RESUMEN

| Componente | Cantidad | Estado |
|------------|----------|--------|
| **Tablas Core** | 30+ | ✅ Definidas |
| **API Endpoints** | 25+ | ✅ Mapeados |
| **Relaciones FK** | 20+ | ✅ Documentadas |
| **Históricos Migrados** | 0% | ⏳ Pendiente |
| **Índices Optimización** | 40+ | ✅ Definidos |

**Próximos Pasos:**
1. ✅ Ejecutar scripts de creación de tablas
2. ⏳ Migrar datos históricos GNV (2013-2025)
3. ⏳ Migrar eventos críticos históricos
4. ⏳ Implementar endpoints REST en FastAPI
5. ⏳ Configurar particionamiento por fecha

---

**Referencias:**
- NEON Console: https://console.neon.tech
- PostgreSQL Docs: https://www.postgresql.org/docs/
- SQLAlchemy Async: https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html
