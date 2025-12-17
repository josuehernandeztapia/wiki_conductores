# ANEXO: ACTUALIZACIONES NEON – SCHEMA, API y MIGRACIÓN

> Fuentes: `NeonDB.docx`, `neon_openapi_full.yml`, `neon_schema_blueprint.csv`, `weathered-scene-29269876_production_neondb_2025-08-17_00-33-29.csv`, `part_equivalences_inserts*.sql`, `Consumos GNV/Archivo Ventas Diarias GNV - Vagonetas AGS.*`.

## 1. Estado de la Documentación

- `CORE_FASE8_NEON_DATABASE.md` ya describe el schema, secciones telematics/business/intelligence y estrategias de migración (`scripts/migrate_consware…`).
- Este anexo confirma que los archivos externos coinciden con dicha documentación y detalla pendientes operativos (carga de datasets, sincronización de la OpenAPI).

## 2. Archivos en Carpeta NEON

| Archivo | Descripción | Estado en la wiki |
|---------|-------------|-------------------|
| `NeonDB.docx` | Resumen en inglés del schema (tablas, campos, relaciones, APIs) | Cubierto en FASE8; se usa como referencia para este anexo. |
| `neon_schema_blueprint.csv` | Diccionario de datos (tabla, campo, tipo, notas) | Referenciado en FASE8; se recomienda cargarlo como anexo/tabla. |
| `neon_openapi_full.yml` | Especificación OpenAPI (paths `/vehicles`, `/location_event`, etc.) | Paths principales listados en FASE8; falta sincronizar versiones y enumerar nuevas rutas en la wiki. |
| `weathered-scene-...csv` | Export (fault_catalog / part_equivalences) con referencias OEM | Parte del anexo postventa; debe cargarse a NEON y cruzarse con `spare_parts`. |
| `Consumos GNV/...` | Dataset histórico GNV (Excel/PDF) | Se menciona en FASE8 (paso 7.1); falta confirmar migración y documentar volumetría. |
| `part_equivalences_inserts*.sql` | Scripts de inserción equivalencias | Usados en anexo postventa; necesitan ejecutarse/validarse en NEON. |

## 3. API (OpenAPI)

Ejemplos de rutas definidas en `neon_openapi_full.yml`:
```
/vehicles, /vehicles/{id}
/location_event, /location_event/{id}
/metric, /metric/{ts}
/hase_scores, /pma_alerts
/spare_parts, /fault_catalog
```
**Pendiente:** versionar este YAML dentro del repo (`/api-spec/neon_openapi_full.yml`) y actualizar la sección API en FASE8 con parámetros/ejemplos.

## 4. Migración Consware → NEON

- `Archivo Ventas Diarias GNV - Vagonetas AGS.xlsx` → `historical_gnv_consumption` (ver script en FASE8).
- Falta confirmar si la migración ya se ejecutó (volumen de registros, último corte) y documentar el job ETL (cron o pipeline) que mantiene la tabla.
- `weathered-scene...csv` muestra catálogos `fault_catalog` y `part_equivalences`; verificar que están alineados con `spare_parts` (ver anexo postventa).

## 5. Diccionario y Catálogos

- `neon_schema_blueprint.csv` contiene tabla/campo/tipo/notes → usarlo para generar una tabla en la wiki o anexarlo como recurso.
- `part_equivalences_inserts*.sql` + `new_part_equivalences_toyota_only.sql` deben correrse en NEON (script `INSERT ... ON CONFLICT DO NOTHING`).
- `weathered-scene...csv` prueba que existen entradas en `fault_catalog`; se deben sincronizar con la nueva tabla de refacciones (ver `ANEXO_POSTVENTA_HIGER.md`).

## 6. Pendientes

1. **Subir OpenAPI**: agregar `neon_openapi_full.yml` al repositorio y referenciarlo en `CORE_FASE8_NEON_DATABASE.md` (sección API). 
2. **Confirmar migraciones**: documentar en FASE8 la última ejecución de los scripts Consware → NEON y el estado de los datasets (número de registros, fecha de corte).
3. **Publicar diccionario**: convertir `neon_schema_blueprint.csv` en tabla Markdown dentro de FASE8 (o anexarlo). 
4. **Validar catálogos**: cruzar `weathered-scene...csv` con NEON para asegurar que `fault_catalog` y `part_equivalences` estén sincronizados.
5. **Integración RAG/PWA**: asegurarse de que `/spare_parts`, `/fault_catalog`, `/hase_scores` expongan la información que consumen el agente postventa y la PWA (ligar a `ANEXO_POSTVENTA_HIGER.md` e IDEAS_18).

Con este anexo se documenta el estado actual de los archivos NEON y se listan las tareas pendientes para cerrar el gap en la wiki.
