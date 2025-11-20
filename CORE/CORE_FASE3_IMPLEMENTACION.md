# CORE FASE 3: PLAN DE IMPLEMENTACIÓN

## 🎯 Objetivo
Roadmap de desarrollo por sprints, definición de endpoints, estructura de código y priorización de features.

---

## 📅 Roadmap de Desarrollo (6 meses a MVP)

### Sprint 0: Setup & Foundations (2 semanas)
```yaml
Backend:
  - ✅ Configuración repositorio Git
  - ✅ Setup Docker Compose (Postgres + Redis)
  - ✅ Estructura FastAPI con Pydantic
  - ✅ SQLAlchemy async models
  - ✅ Alembic migrations setup
  - ✅ Pytest configuration
  - ✅ CI/CD pipeline (GitHub Actions)

Frontend:
  - Angular 18 project setup
  - Angular Material + Tailwind
  - Routing + lazy loading
  - HTTP interceptors (JWT)
  - Environment configs

Infraestructura:
  - AWS account setup
  - RDS PostgreSQL provisioning
  - ElastiCache Redis
  - S3 buckets
  - CloudFront CDN
```

### Sprint 1-2: Autenticación & Conductores (4 semanas)
```yaml
Endpoints:
  - POST /api/v1/auth/register
  - POST /api/v1/auth/login
  - POST /api/v1/auth/refresh
  - GET  /api/v1/conductores/me
  - PUT  /api/v1/conductores/me
  - POST /api/v1/conductores/upload-document

Integraciones:
  - Metamap KYC (verificación identidad)
  - S3 (almacenamiento documentos)
  - SendGrid (emails bienvenida)

Frontend:
  - Página registro
  - Página login
  - Dashboard conductor
  - Perfil editable
  - Upload de documentos

Testing:
  - Unit tests (auth service)
  - Integration tests (endpoints)
  - E2E (Cypress)
```

### Sprint 3-4: Cotizador & Solicitudes (4 semanas)
```yaml
Endpoints:
  - POST /api/v1/cotizador/quote
  - GET  /api/v1/cotizador/scenarios
  - POST /api/v1/applications/submit
  - GET  /api/v1/applications/{id}
  - GET  /api/v1/applications (list con filtros)

Business Logic:
  - Cotizador service (4 escenarios)
  - PMT calculation
  - Payment schedule generator
  - Application validation

Frontend:
  - Cotizador interactivo (público)
  - Formulario solicitud crédito
  - Lista mis solicitudes
  - Detalle solicitud

Testing:
  - Unit tests cotizador
  - Validación escenarios
  - Edge cases (montos, plazos)
```

### Sprint 5-6: Motor HASE v1 (Básico) (4 semanas)
```yaml
Endpoints:
  - POST /api/v1/hase/score (interno)
  - GET  /api/v1/hase/features/{conductor_id}

Integraciones:
  - Geotab API (telemetría)
  - Conekta API (ingresos)

Motor HASE:
  - Feature extraction (50 features telemetría)
  - Rule-based scoring (v1 sin ML)
  - SINOSURE tier assignment
  - Recommendation engine

Data Pipeline:
  - Cron job: sync Geotab (cada hora)
  - Cron job: sync Conekta (cada 6 hrs)
  - Data validation + cleaning

Testing:
  - Unit tests feature extraction
  - Scoring logic validation
  - Mock Geotab/Conekta data
```

### Sprint 7-8: Aprobación & Créditos (4 semanas)
```yaml
Endpoints:
  - POST /api/v1/creditos/approve
  - GET  /api/v1/creditos/{id}
  - GET  /api/v1/creditos (list)
  - POST /api/v1/creditos/{id}/disburse
  - GET  /api/v1/creditos/{id}/schedule

Integraciones:
  - NEON Bank (dispersión)
  - Odoo ERP (facturación)
  - SINOSURE (reporte)

Business Logic:
  - Approval workflow
  - Payment schedule creation
  - Credit disbursement
  - Contract generation (PDF)

Frontend:
  - Panel aprobaciones (admin)
  - Detalle crédito aprobado
  - Calendario de pagos
  - Contrato digital

Testing:
  - Approval flow end-to-end
  - Payment schedule accuracy
  - Disbursement simulation
```

### Sprint 9-10: Pagos & Cobranza (4 semanas)
```yaml
Endpoints:
  - POST /api/v1/pagos/process
  - GET  /api/v1/pagos/{credito_id}
  - POST /api/v1/pagos/webhook/conekta
  - GET  /api/v1/pagos/upcoming

Integraciones:
  - Conekta payments (card, SPEI, OXXO)
  - Twilio SMS (recordatorios)
  - SendGrid (emails cobranza)

Business Logic:
  - Payment processing
  - Late payment detection
  - 5-level collection system
  - Automated notifications

Cron Jobs:
  - Daily: Update late statuses
  - Daily: Send payment reminders
  - Weekly: Supervisor escalation

Frontend:
  - Página pagar mi mensualidad
  - Historial de pagos
  - Recibos descargables
  - Notificaciones en app

Testing:
  - Payment processing flow
  - Webhook handling
  - Late payment logic
  - Notification delivery
```

### Sprint 11-12: Pausas & Chatbot (4 semanas)
```yaml
Endpoints:
  - POST /api/v1/pausas/request
  - GET  /api/v1/pausas/{credito_id}
  - PUT  /api/v1/pausas/{id}/approve
  - POST /api/v1/chat/message
  - GET  /api/v1/chat/history

Integraciones:
  - OpenAI GPT-4 (chatbot)
  - Pinecone (RAG context)

Business Logic:
  - Pausa eligibility check
  - Payment schedule adjustment
  - AI chatbot with RAG
  - Vector search

Data:
  - Embeddings de documentación
  - Index en Pinecone (10K vectores)

Frontend:
  - Solicitar pausa de pago
  - Chatbot widget
  - Chat history

Testing:
  - Pausa logic
  - Chatbot responses
  - RAG accuracy
```

---

## 🔌 Definición de APIs (60+ Endpoints)

### Autenticación (4 endpoints)
```http
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
```

### Conductores (6 endpoints)
```http
GET    /api/v1/conductores/me
PUT    /api/v1/conductores/me
POST   /api/v1/conductores/upload-document
GET    /api/v1/conductores/{id}
DELETE /api/v1/conductores/me
GET    /api/v1/conductores (admin)
```

### Cotizador (3 endpoints)
```http
POST   /api/v1/cotizador/quote
GET    /api/v1/cotizador/scenarios
GET    /api/v1/cotizador/vehicles
```

### Applications (7 endpoints)
```http
POST   /api/v1/applications/submit
GET    /api/v1/applications/{id}
GET    /api/v1/applications
PUT    /api/v1/applications/{id}
DELETE /api/v1/applications/{id}
GET    /api/v1/applications/{id}/score
POST   /api/v1/applications/{id}/decide (admin)
```

### Créditos (10 endpoints)
```http
POST   /api/v1/creditos/approve (admin)
GET    /api/v1/creditos/{id}
GET    /api/v1/creditos
PUT    /api/v1/creditos/{id}
POST   /api/v1/creditos/{id}/disburse (admin)
GET    /api/v1/creditos/{id}/schedule
GET    /api/v1/creditos/{id}/balance
POST   /api/v1/creditos/{id}/early-payment
GET    /api/v1/creditos/{id}/contract
GET    /api/v1/creditos/stats (admin)
```

### Pagos (8 endpoints)
```http
POST   /api/v1/pagos/process
GET    /api/v1/pagos/{id}
GET    /api/v1/pagos
GET    /api/v1/pagos/upcoming
GET    /api/v1/pagos/{id}/receipt
POST   /api/v1/pagos/webhook/conekta
GET    /api/v1/pagos/late (admin)
POST   /api/v1/pagos/{id}/forgive (admin)
```

### Telemetría (5 endpoints)
```http
GET    /api/v1/telemetria/{conductor_id}
GET    /api/v1/telemetria/{conductor_id}/summary
POST   /api/v1/telemetria/sync (admin)
GET    /api/v1/telemetria/devices
POST   /api/v1/telemetria/link-device
```

### Pausas (5 endpoints)
```http
POST   /api/v1/pausas/request
GET    /api/v1/pausas/{id}
GET    /api/v1/pausas
PUT    /api/v1/pausas/{id}/approve (admin)
PUT    /api/v1/pausas/{id}/reject (admin)
```

### Motor HASE (4 endpoints)
```http
POST   /api/v1/hase/score (interno)
GET    /api/v1/hase/features/{conductor_id}
GET    /api/v1/hase/model-info
POST   /api/v1/hase/retrain (admin)
```

### Chatbot (4 endpoints)
```http
POST   /api/v1/chat/message
GET    /api/v1/chat/history
DELETE /api/v1/chat/history
GET    /api/v1/chat/suggestions
```

### Admin (8 endpoints)
```http
GET    /api/v1/admin/dashboard
GET    /api/v1/admin/conductores
GET    /api/v1/admin/applications
GET    /api/v1/admin/creditos
GET    /api/v1/admin/portfolio-health
GET    /api/v1/admin/collections
POST   /api/v1/admin/users (create admin)
GET    /api/v1/admin/audit-logs
```

### Health & Info (3 endpoints)
```http
GET    /
GET    /health
GET    /api/v1/info
```

**Total: 67 endpoints**

---

## 📁 Estructura de Código Backend

```
conductores-backend/
├── alembic/
│   ├── versions/
│   │   ├── 001_initial_schema.py
│   │   ├── 002_add_sinosure_tier.py
│   │   └── ...
│   ├── env.py
│   └── script.py.mako
│
├── config/
│   └── settings.py                 # Pydantic Settings
│
├── database/
│   ├── schemas/                    # SQL DDL
│   │   ├── 01_conductores.sql
│   │   ├── 02_creditos.sql
│   │   └── ...
│   └── init_database.sql
│
├── src/
│   ├── main.py                     # FastAPI app
│   │
│   ├── api/
│   │   ├── dependencies.py         # JWT auth, DB session
│   │   └── routes/
│   │       ├── __init__.py
│   │       ├── auth.py
│   │       ├── conductores.py
│   │       ├── cotizador.py
│   │       ├── applications.py
│   │       ├── creditos.py
│   │       ├── pagos.py
│   │       ├── telemetria.py
│   │       ├── pausas.py
│   │       ├── hase.py
│   │       ├── chat.py
│   │       └── admin.py
│   │
│   ├── models/                     # Pydantic schemas
│   │   ├── __init__.py
│   │   ├── conductor.py
│   │   ├── credito.py
│   │   ├── application.py
│   │   ├── pago.py
│   │   ├── telemetria.py
│   │   └── pausa.py
│   │
│   ├── database/                   # SQLAlchemy ORM
│   │   ├── __init__.py
│   │   ├── session.py              # Async engine
│   │   ├── base.py                 # Base class
│   │   └── models/
│   │       ├── __init__.py
│   │       ├── conductor.py
│   │       ├── credito.py
│   │       ├── application.py
│   │       ├── pago.py
│   │       ├── telemetria.py
│   │       └── pausa.py
│   │
│   ├── services/                   # Business logic
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── cotizador.py
│   │   ├── motor_hase.py
│   │   ├── cobranza.py
│   │   ├── ai_chatbot.py
│   │   └── notifications.py
│   │
│   ├── integrations/               # External APIs
│   │   ├── __init__.py
│   │   ├── geotab_client.py
│   │   ├── conekta_client.py
│   │   ├── metamap_client.py
│   │   ├── neon_client.py
│   │   ├── odoo_client.py
│   │   ├── openai_client.py
│   │   ├── pinecone_client.py
│   │   └── sinosure_client.py
│   │
│   └── utils/
│       ├── __init__.py
│       ├── security.py             # JWT, hashing
│       ├── validators.py
│       └── helpers.py
│
├── tests/
│   ├── conftest.py                 # Pytest fixtures
│   ├── unit/
│   │   ├── test_auth.py
│   │   ├── test_cotizador.py
│   │   ├── test_motor_hase.py
│   │   └── ...
│   └── integration/
│       ├── test_api.py
│       ├── test_applications.py
│       └── ...
│
├── scripts/
│   ├── sync_geotab.py              # Cron job
│   ├── update_late_payments.py     # Cron job
│   └── train_hase_model.py
│
├── .env.example
├── .gitignore
├── requirements.txt
├── docker-compose.yml
├── Dockerfile
├── Makefile
├── pytest.ini
└── README.md
```

---

## 🚀 Siguiente Fase

**→ CORE_FASE4_INTEGRACIONES.md**
- Detalles técnicos de cada integración
- Autenticación y webhooks
- Rate limits y errores
- Flujos de datos completos
