# ANEXO: NEON SCHEMA BLUEPRINT

Diccionario completo migrado desde `neon_schema_blueprint.csv`. Cada tabla incluye los campos, tipos y notas relevantes para NEON PostgreSQL.

## Tabla `vehicle`

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | `text` | PK, unique code |
| `vin` | `text` | unique - Vehicle Identification Number |
| `plate` | `text` | unique |
| `make` | `text` |  |
| `model` | `text` |  |
| `year` | `integer` |  |
| `alta_at` | `timestamp` |  |

## Tabla `location_event`

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | `bigserial` | PK |
| `vehicle_id` | `text` | FK → vehicle.id |
| `ts` | `timestamp` |  |
| `lat` | `double precision` |  |
| `lon` | `double precision` |  |
| `speed_kph` | `double precision` |  |
| `heading_deg` | `double precision` |  |
| `ignition` | `boolean` |  |
| `accuracy_m` | `double precision` |  |
| `event_id` | `uuid` |  |
| `inserted_at` | `timestamp` |  |

## Tabla `metric`

| Campo | Tipo | Notas |
|-------|------|-------|
| `vehicle_id` | `text` | FK |
| `ts` | `timestamp` |  |
| `odometer_km` | `double precision` |  |
| `rpm` | `double precision` |  |
| `battery_v` | `double precision` |  |
| `dtc_count` | `integer` |  |
| `coolant_temp_c` | `double precision` |  |
| `engine_load_pct` | `double precision` |  |
| `oil_level_pct` | `double precision` |  |
| `oil_pressure_kpa` | `double precision` |  |
| `air_flow_maf` | `double precision` |  |
| `alternator_v` | `double precision` |  |
| `fuel_level_pct` | `double precision` |  |
| `fuel_consumption_rate_lph` | `double precision` |  |
| `fuel_economy_l100km` | `double precision` |  |
| `idle_time_sec` | `integer` |  |

## Tabla `driver_behavior_event`

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | `bigserial` | PK |
| `vehicle_id` | `text` | FK |
| `driver_id` | `text` |  |
| `ts` | `timestamp` |  |
| `event_type` | `text` |  |
| `value` | `double precision` | e.g. g-force |
| `raw_data` | `jsonb` |  |

## Tabla `dtc_event`

| Campo | Tipo | Notas |
|-------|------|-------|
| `vehicle_id` | `text` | FK |
| `code` | `text` |  |
| `description` | `text` |  |
| `severity` | `text` |  |
| `ts` | `timestamp` |  |

## Tabla `customers`

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | `uuid` | PK |
| `external_id` | `varchar` |  |
| `first_name` | `varchar` |  |
| `last_name` | `varchar` |  |
| `email` | `varchar` |  |
| `phone` | `varchar` |  |
| `status` | `varchar` |  |
| `created_at` | `timestamp` |  |
| `updated_at` | `timestamp` |  |

## Tabla `contracts`

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | `uuid` | PK |
| `customer_id` | `uuid` | FK |
| `vehicle_id` | `text` | FK |
| `contract_type` | `text` |  |
| `product_code` | `varchar` |  |
| `status` | `varchar` |  |
| `created_at` | `timestamp` |  |
| `updated_at` | `timestamp` |  |

## Tabla `transactions`

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | `uuid` | PK |
| `customer_id` | `uuid` | FK |
| `contract_id` | `uuid` | FK |
| `transaction_type` | `varchar` |  |
| `amount` | `numeric` |  |
| `currency_code` | `char` |  |
| `processed_at` | `timestamp` |  |

## Tabla `onboarding_verifications`

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | `uuid` | PK |
| `customer_id` | `uuid` | FK |
| `provider` | `varchar` |  |
| `status` | `varchar` |  |
| `verified_at` | `timestamp` |  |
| `raw_response_payload` | `jsonb` |  |

## Tabla `historical_gnv_consumption`

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | `integer` | PK |
| `vehicle_id` | `varchar` | FK |
| `refuel_date` | `timestamp` |  |
| `volume_m3` | `numeric` |  |
| `cost_total` | `numeric` |  |
| `odometer_reading` | `integer` |  |
| `driver_id` | `varchar` |  |

## Tabla `historical_critical_events`

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | `integer` | PK |
| `vehicle_id` | `varchar` | FK |
| `event_type` | `varchar` |  |
| `event_timestamp` | `timestamp` |  |
| `severity_level` | `varchar` |  |
| `fault_code` | `varchar` |  |
| `description` | `text` |  |

## Tabla `hase_scores`

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | `uuid` | PK |
| `customer_id` | `uuid` | FK |
| `contract_id` | `uuid` | FK |
| `vehicle_id` | `uuid` | FK |
| `score_period_start` | `date` |  |
| `score_period_end` | `date` |  |
| `health_score` | `numeric` |  |
| `overall_score` | `numeric` |  |
| `created_at` | `timestamp` |  |

## Tabla `pma_alerts`

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | `uuid` | PK |
| `customer_id` | `uuid` | FK |
| `contract_id` | `uuid` | FK |
| `vehicle_id` | `uuid` | FK |
| `alert_type` | `varchar` |  |
| `severity` | `varchar` |  |
| `status` | `varchar` |  |
| `title` | `varchar` |  |
| `created_at` | `timestamp` |  |

## Tabla `fault_catalog`

| Campo | Tipo | Notas |
|-------|------|-------|
| `falla_id` | `integer` | PK |
| `codigo_falla` | `text` | unique |
| `descripcion_falla` | `text` |  |
| `categoria_principal` | `text` |  |
| `subcategoria` | `text` |  |
| `criticidad` | `text` |  |
| `tipificacion_obd2` | `bool` |  |
| `codigo_obd2` | `text` |  |
| `solucion_sugerida` | `text` |  |
| `refaccion_recomendada` | `text` |  |
| `created_at` | `timestamp` |  |
| `updated_at` | `timestamp` |  |

