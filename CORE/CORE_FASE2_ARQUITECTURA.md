# CORE FASE 2: ARQUITECTURA TÉCNICA

## 🎯 Objetivo de esta Fase
Diseñar la arquitectura técnica completa del sistema **Conductores del Mundo**, definiendo stack tecnológico, componentes, integraciones y flujos de datos.

---

## 🏗️ Arquitectura General del Sistema

### Diagrama de Alto Nivel

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CAPA DE PRESENTACIÓN                         │
├─────────────────────────────────────────────────────────────────────┤
│  PWA Angular 18                                                      │
│  ├── Cotizador (público)                                            │
│  ├── Portal Conductor (autenticado)                                 │
│  ├── Panel Admin (roles)                                            │
│  └── Chatbot IA (OpenAI GPT-4)                                      │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTPS/JWT
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         CAPA DE APLICACIÓN                           │
├─────────────────────────────────────────────────────────────────────┤
│  Backend API (FastAPI Python 3.11+)                                 │
│  ├── API REST (60+ endpoints)                                       │
│  ├── Autenticación JWT + OAuth2                                     │
│  ├── Validación Pydantic                                            │
│  └── Rate Limiting + CORS                                           │
└─────────────────────────────────────────────────────────────────────┘
                                    │
          ┌─────────────────────────┼─────────────────────────┐
          │                         │                         │
          ▼                         ▼                         ▼
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  CAPA DE NEGOCIO │    │  CAPA DE DATOS   │    │ CAPA INTEGRACIÓN │
├──────────────────┤    ├──────────────────┤    ├──────────────────┤
│ Motor HASE       │    │ PostgreSQL 15    │    │ Geotab API       │
│ (Scoring ML)     │    │ (Async/Pool)     │    │ Conekta API      │
│                  │    │                  │    │ Metamap API      │
│ Cotizador        │    │ Redis 7          │    │ NEON Bank API    │
│ (4 escenarios)   │    │ (Cache/Session)  │    │ Odoo ERP API     │
│                  │    │                  │    │ OpenAI API       │
│ Cobranza         │    │ Alembic          │    │ Pinecone API     │
│ (5 niveles)      │    │ (Migrations)     │    │ SINOSURE API     │
│                  │    │                  │    │                  │
│ AI Chatbot       │    │ Pinecone Vector  │    │ Twilio SMS       │
│ (RAG)            │    │ (RAG context)    │    │ SendGrid Email   │
│                  │    │                  │    │                  │
│ Autenticación    │    │ S3 Compatible    │    │ Webhooks         │
│ (Bcrypt+JWT)     │    │ (Documentos)     │    │ (Conekta/Odoo)   │
│                  │    │                  │    │                  │
│ Notificaciones   │    │                  │    │                  │
│ (Multi-canal)    │    │                  │    │                  │
└──────────────────┘    └──────────────────┘    └──────────────────┘
```

---

## 🔧 Stack Tecnológico

### Backend (Python Ecosystem)

```yaml
Lenguaje:
  - Python 3.11+
  - Type Hints (mypy strict)
  - Async/await (asyncio)

Framework Web:
  - FastAPI 0.104+
    - Pydantic 2.0 (validación)
    - Starlette (ASGI)
    - Uvicorn (servidor)

ORM & Database:
  - SQLAlchemy 2.0 (async)
  - asyncpg (PostgreSQL driver)
  - Alembic (migraciones)

Machine Learning:
  - XGBoost 2.0+ (scoring HASE)
  - scikit-learn (preprocessing)
  - pandas (feature engineering)
  - joblib (model serialization)

Autenticación:
  - python-jose (JWT)
  - passlib + bcrypt (hashing)
  - python-multipart (forms)

HTTP Clients:
  - httpx (async HTTP)
  - requests (sync fallback)

Testing:
  - pytest
  - pytest-asyncio
  - pytest-cov (coverage)
  - httpx test client

Utilidades:
  - python-dotenv (config)
  - pydantic-settings
  - tenacity (retry logic)
  - python-dateutil
```

### Frontend (Angular PWA)

```yaml
Framework:
  - Angular 18
  - TypeScript 5.0+
  - RxJS 7 (reactive)

UI Components:
  - Angular Material 18
  - Tailwind CSS 3.4
  - Chart.js (gráficas)

PWA:
  - @angular/pwa
  - Service Workers
  - IndexedDB (offline)

State Management:
  - NgRx Store
  - NgRx Effects

HTTP:
  - HttpClient (interceptors)
  - JWT Interceptor

Build:
  - Angular CLI
  - Webpack 5
  - Ahead-of-Time (AOT)
```

### Bases de Datos

```yaml
PostgreSQL 15:
  Uso: Base de datos principal
  Features:
    - UUID nativo (gen_random_uuid)
    - JSONB para metadata
    - Full-text search
    - Particionamiento (pagos por mes)
    - Connection pooling (pgbouncer)
  Tamaño estimado: 100GB Año 1

Redis 7:
  Uso: Cache + Sessions
  Features:
    - Cache de queries (TTL 5-60 min)
    - Rate limiting (sliding window)
    - Session storage (JWT blacklist)
    - Bull queues (jobs async)
  Tamaño estimado: 8GB RAM

Pinecone Vector DB:
  Uso: RAG para chatbot
  Features:
    - Embeddings OpenAI (1536 dims)
    - Búsqueda semántica
    - 10K vectores (documentación)
  Plan: Starter ($70/mes)
```

### Infraestructura

```yaml
Cloud Provider: AWS
  Región: us-east-1 (N. Virginia)

Servicios:
  - EC2: t3.medium (backend API)
  - RDS PostgreSQL: db.t3.large
  - ElastiCache Redis: cache.t3.micro
  - S3: Documentos + backups
  - CloudFront: CDN para frontend
  - Route 53: DNS
  - ALB: Load balancer
  - CloudWatch: Logs + métricas
  - Secrets Manager: API keys

Containerización:
  - Docker 24+
  - Docker Compose (dev)
  - ECR (registry)

Orchestración:
  - AWS ECS Fargate (producción)
  - Auto-scaling (2-10 instancias)

CI/CD:
  - GitHub Actions
  - Deploy on merge to main
  - Automated tests + linting
```

---

## 🔌 Arquitectura de Integraciones

### Mapa de Integraciones (8 APIs Externas)

```
┌─────────────────────────────────────────────────────────────────────┐
│                       CONDUCTORES DEL MUNDO API                      │
└─────────────────────────────────────────────────────────────────────┘
           │
           ├──→ [1] Geotab API
           │     ├── Endpoint: https://my.geotab.com/apiv1
           │     ├── Auth: Session ID (username/password)
           │     ├── Uso: Telemetría GPS (trips, devices, driver scores)
           │     ├── Frecuencia: Polling cada 1 hora
           │     └── Data: ~1MB/conductor/mes
           │
           ├──→ [2] Conekta API
           │     ├── Endpoint: https://api.conekta.io
           │     ├── Auth: Bearer token (API key)
           │     ├── Uso: Procesamiento pagos (cards, SPEI, OXXO)
           │     ├── Webhooks: charge.paid, charge.failed
           │     └── Comisión: 3.6% + $3 MXN por transacción
           │
           ├──→ [3] Metamap API
           │     ├── Endpoint: https://api.metamap.com/v2
           │     ├── Auth: Bearer token
           │     ├── Uso: KYC biométrico (INE, selfie, liveness)
           │     ├── Webhook: verification.completed
           │     └── Costo: $1.50 USD por verificación
           │
           ├──→ [4] NEON Bank API
           │     ├── Endpoint: https://api.neon.com.br/v1
           │     ├── Auth: OAuth2 client credentials
           │     ├── Uso: Dispersión de créditos (ACH)
           │     ├── Tiempo: 24-48 hrs
           │     └── Límite: $500K MXN/transacción
           │
           ├──→ [5] Odoo ERP API
           │     ├── Endpoint: https://conductores.odoo.com/xmlrpc/2
           │     ├── Auth: XML-RPC (db, username, password)
           │     ├── Uso: CRM + Facturación CFDI 4.0
           │     ├── Módulos: crm, account, l10n_mx
           │     └── Sync: Bidireccional cada 15 min
           │
           ├──→ [6] OpenAI API
           │     ├── Endpoint: https://api.openai.com/v1
           │     ├── Auth: Bearer token
           │     ├── Uso: Chatbot (GPT-4-turbo) + Embeddings
           │     ├── Modelo chat: gpt-4-turbo-preview
           │     ├── Modelo embeddings: text-embedding-3-small
           │     └── Costo: ~$0.01 USD por 1K tokens
           │
           ├──→ [7] Pinecone API
           │     ├── Endpoint: https://<index>.pinecone.io
           │     ├── Auth: API key (header)
           │     ├── Uso: Vector DB para RAG (contexto chatbot)
           │     ├── Index: conductores-kb (1536 dims)
           │     └── Plan: Starter $70/mes (10K vectores)
           │
           └──→ [8] SINOSURE API
                 ├── Endpoint: https://api.sinosure.com.cn (custom)
                 ├── Auth: Mutual TLS + firma digital
                 ├── Uso: Seguro de crédito ($10M USD línea)
                 ├── Reportes: Mensual (cartera + siniestros)
                 └── Cobertura: Hasta 90% del saldo insoluto
```

### Estrategia de Resiliencia

```python
# Patrón Circuit Breaker para cada integración
class IntegrationClient:
    def __init__(self):
        self.circuit_breaker = CircuitBreaker(
            failure_threshold=5,      # 5 fallos consecutivos
            timeout=30,               # 30 segundos
            recovery_timeout=60       # Reintentar en 60 seg
        )

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10)
    )
    async def call_api(self, endpoint, payload):
        # Retry con backoff exponencial
        pass

# Cache para reducir calls externos
@cached(ttl=3600)  # 1 hora
async def get_geotab_trips(device_id: str, from_date: datetime):
    return await geotab_client.get_trips(device_id, from_date)
```

---

## 📊 Modelo de Datos (ERD)

### Diagrama Entidad-Relación

```
┌─────────────────────────┐
│      conductores        │
├─────────────────────────┤
│ PK id (UUID)            │
│    nombre_completo      │
│    email (UNIQUE)       │
│    password_hash        │
│    telefono             │
│    geotab_device_id     │
│    conekta_customer_id  │
│    metamap_verification │
│    neon_account_id      │
│    odoo_partner_id      │
│    created_at           │
│    updated_at           │
└─────────────────────────┘
         │ 1
         │
         │ N
         ▼
┌─────────────────────────┐       ┌─────────────────────────┐
│     applications        │       │       creditos          │
├─────────────────────────┤       ├─────────────────────────┤
│ PK id (UUID)            │       │ PK id (UUID)            │
│ FK conductor_id         │───┐   │ FK conductor_id         │
│    monto_solicitado     │   │   │ FK application_id       │
│    plazo_meses          │   │   │    monto_aprobado       │
│    vehiculo_tipo        │   │   │    tasa_aprobada        │
│    ingresos_mensuales   │   │   │    plazo_meses          │
│    score_hase           │   │   │    score_hase           │
│    sinosure_tier        │   │   │    sinosure_tier        │
│    decision             │   │   │    balance_actual       │
│    decision_reason      │   │   │    pausas_disponibles   │
│    status               │   │   │    status               │
│    created_at           │   │   │    disbursed_at         │
└─────────────────────────┘   │   │    created_at           │
                              │   └─────────────────────────┘
                              │            │ 1
                              │            │
                              │            │ N
                              │            ▼
                              │   ┌─────────────────────────┐
                              │   │        pagos            │
                              │   ├─────────────────────────┤
                              │   │ PK id (UUID)            │
                              │   │ FK credito_id           │
                              │   │    numero_pago          │
                              │   │    monto_programado     │
                              │   │    fecha_pago_esperada  │
                              │   │    monto_pagado         │
                              │   │    fecha_pago_real      │
                              │   │    conekta_charge_id    │
                              │   │    conekta_order_id     │
                              │   │    status               │
                              │   │    dias_retraso         │
                              │   │    created_at           │
                              │   └─────────────────────────┘
                              │
                              │            ┌─────────────────────────┐
                              │            │      telemetria         │
                              │            ├─────────────────────────┤
                              └────────────│ PK id (UUID)            │
                                           │ FK conductor_id         │
                                           │    geotab_trip_id       │
                                           │    fecha                │
                                           │    horas_activas        │
                                           │    km_recorridos        │
                                           │    driver_score         │
                                           │    eventos_riesgo       │
                                           │    velocidad_promedio   │
                                           │    fuel_consumption     │
                                           │    created_at           │
                                           └─────────────────────────┘

┌─────────────────────────┐
│        pausas           │
├─────────────────────────┤
│ PK id (UUID)            │
│ FK credito_id           │
│    fecha_inicio         │
│    fecha_fin            │
│    motivo               │
│    aprobado_por         │
│    status               │
│    created_at           │
└─────────────────────────┘
```

### Índices Críticos

```sql
-- Conductores
CREATE INDEX idx_conductores_email ON conductores(email);
CREATE INDEX idx_conductores_geotab ON conductores(geotab_device_id);
CREATE INDEX idx_conductores_created ON conductores(created_at DESC);

-- Applications
CREATE INDEX idx_applications_conductor ON applications(conductor_id);
CREATE INDEX idx_applications_status ON applications(status);
CREATE INDEX idx_applications_created ON applications(created_at DESC);

-- Créditos
CREATE INDEX idx_creditos_conductor ON creditos(conductor_id);
CREATE INDEX idx_creditos_status ON creditos(status);
CREATE INDEX idx_creditos_sinosure ON creditos(sinosure_tier);

-- Pagos (particionado por mes)
CREATE INDEX idx_pagos_credito ON pagos(credito_id);
CREATE INDEX idx_pagos_status ON pagos(status);
CREATE INDEX idx_pagos_fecha_esperada ON pagos(fecha_pago_esperada);
CREATE INDEX idx_pagos_late ON pagos(status) WHERE status LIKE 'late%';

-- Telemetría (particionado por mes)
CREATE INDEX idx_telemetria_conductor ON telemetria(conductor_id);
CREATE INDEX idx_telemetria_fecha ON telemetria(fecha DESC);
CREATE INDEX idx_telemetria_geotab ON telemetria(geotab_trip_id);
```

---

## 🔐 Seguridad

### Capas de Seguridad

```yaml
1. Autenticación:
   - JWT tokens (HS256)
   - Access token: 1 hora
   - Refresh token: 7 días
   - Token blacklist en Redis
   - Password hash: bcrypt (12 rounds)

2. Autorización:
   - RBAC (Role-Based Access Control)
   - Roles: admin, analyst, conductor
   - Scopes: read:own, write:own, admin:all

3. Comunicación:
   - HTTPS only (TLS 1.3)
   - HSTS headers
   - Certificate pinning (mobile)

4. API Protection:
   - Rate limiting (100 req/min por IP)
   - CORS whitelist
   - Input validation (Pydantic)
   - SQL injection prevention (ORM)
   - XSS prevention (CSP headers)

5. Datos Sensibles:
   - PII encryption at rest (AES-256)
   - Secrets en AWS Secrets Manager
   - API keys rotación mensual
   - Logs sin PII (ofuscación)

6. Compliance:
   - PCI-DSS (no almacenar tarjetas)
   - GDPR/LFPDPPP (derecho al olvido)
   - Auditoría de accesos
```

---

## 🚀 Siguiente Fase

**→ CORE_FASE3_IMPLEMENTACION.md**
- Plan de desarrollo por sprints
- Definición de APIs (endpoints)
- Estructura de código
- Roadmap técnico
