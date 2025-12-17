# CORE FASE 4: INTEGRACIONES EXTERNAS

## 🎯 Objetivo
Documentar técnicamente las 8 integraciones externas, incluyendo autenticación, endpoints, webhooks, rate limits y manejo de errores.

---

## 🔌 Integración 1: Geotab GPS Telemetry

### Información General
```yaml
Proveedor: Geotab Inc.
API: MyGeotab API
Versión: v1
Base URL: https://my.geotab.com/apiv1
Documentación: https://developers.geotab.com/
Costo: $25 USD/mes por dispositivo
Uso: Obtener datos de telemetría GPS (trips, scores)
```

### Autenticación
```python
# Session-based authentication
POST https://my.geotab.com/apiv1
{
  "method": "Authenticate",
  "params": {
    "database": "conductores_mx",
    "userName": "admin@conductores.com",
    "password": "********"
  }
}

# Response
{
  "result": {
    "credentials": {
      "database": "conductores_mx",
      "sessionId": "abc123...",
      "userName": "admin@conductores.com"
    }
  }
}

# Session duration: 14 días
# Renovar antes de expiración
```

### Endpoints Utilizados
```python
# 1. Obtener dispositivos
GET_DEVICES = {
    "method": "Get",
    "params": {
        "typeName": "Device",
        "credentials": {...}
    }
}

# 2. Obtener viajes (trips)
GET_TRIPS = {
    "method": "Get",
    "params": {
        "typeName": "Trip",
        "search": {
            "deviceSearch": {"id": "b1234"},
            "fromDate": "2024-01-01T00:00:00.000Z",
            "toDate": "2024-01-31T23:59:59.999Z"
        },
        "credentials": {...}
    }
}

# 3. Obtener driver scores
GET_DRIVER_CHANGES = {
    "method": "Get",
    "params": {
        "typeName": "DriverChange",
        "search": {
            "deviceSearch": {"id": "b1234"},
            "fromDate": "..."
        },
        "credentials": {...}
    }
}
```

### Features Extraídas
```python
# 50+ features de telemetría
features_telemetria = {
    # Constancia
    "dias_trabajados_7d": int,
    "dias_trabajados_30d": int,
    "dias_trabajados_90d": int,

    # Productividad
    "horas_activas_promedio_7d": float,
    "horas_activas_promedio_30d": float,
    "km_recorridos_7d": float,
    "km_recorridos_30d": float,

    # Seguridad
    "driver_score_promedio": float,  # 0-100
    "eventos_frenada_brusca": int,
    "eventos_aceleracion_brusca": int,
    "eventos_exceso_velocidad": int,

    # Eficiencia
    "consumo_combustible_promedio": float,
    "idle_time_porcentaje": float,
    "velocidad_promedio": float,
}
```

### Rate Limits & Estrategia
```yaml
Rate Limit: 300 requests/min
Strategy:
  - Polling cada 1 hora (no real-time)
  - Batch requests (max 50 devices)
  - Exponential backoff on 429
  - Cache Redis (TTL 1 hora)
```

---

## 🔌 Integración 2: Conekta Payments

### Información General
```yaml
Proveedor: Conekta (Stripe para Latinoamérica)
API: Conekta API
Versión: v2.0
Base URL: https://api.conekta.io
Documentación: https://developers.conekta.com/
Comisión: 3.6% + $3 MXN por transacción
Uso: Procesamiento de pagos (tarjetas, SPEI, OXXO)
```

### Autenticación
```bash
# API Key (Bearer token)
curl https://api.conekta.io/customers \
  -H "Authorization: Bearer key_xxxxxxxxxxxxx" \
  -H "Accept: application/vnd.conekta-v2.1.0+json"
```

### Flujo de Pago
```python
# 1. Crear customer
POST /customers
{
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "phone": "+5215512345678"
}

# 2. Crear order
POST /orders
{
  "currency": "MXN",
  "customer_info": {"customer_id": "cus_123"},
  "line_items": [{
    "name": "Pago Mensualidad Crédito",
    "unit_price": 856700,  # Centavos
    "quantity": 1
  }],
  "charges": [{
    "payment_method": {
      "type": "card",
      "token_id": "tok_test_visa_4242"
    }
  }]
}

# 3. Webhook (charge.paid)
POST https://conductores.com/api/v1/pagos/webhook/conekta
{
  "type": "charge.paid",
  "data": {
    "object": {
      "id": "chr_123",
      "amount": 856700,
      "status": "paid",
      "order_id": "ord_456"
    }
  }
}
```

### Métodos de Pago Soportados
```yaml
Tarjetas:
  - Visa, MasterCard, American Express
  - 3D Secure opcional
  - Guardar tarjeta (tokenización)

SPEI (Transferencia):
  - CLABE interbancaria
  - Confirmación 24-48 hrs
  - Sin comisión extra

OXXO (Efectivo):
  - Código de barras
  - Expiración 3 días
  - Confirmación 1-2 hrs
```

### Webhooks Configurados
```python
WEBHOOK_EVENTS = [
    "charge.paid",           # Pago exitoso
    "charge.failed",         # Pago fallido
    "charge.refunded",       # Reembolso
    "charge.chargeback",     # Contracargo
    "order.paid",            # Orden completa
]

# Validación firma webhook
def validate_webhook(payload: str, signature: str) -> bool:
    expected = hmac_sha256(payload, CONEKTA_WEBHOOK_SECRET)
    return hmac.compare_digest(signature, expected)
```

---

## 🔌 Integración 3: Metamap KYC

### Información General
```yaml
Proveedor: Metamap (ex-Mati)
API: Metamap API
Versión: v2
Base URL: https://api.metamap.com/v2
Documentación: https://docs.metamap.com/
Costo: $1.50 USD por verificación
Uso: KYC biométrico (INE, selfie, liveness)
```

### Flujo de Verificación
```python
# 1. Crear identity
POST /identities
Headers: Authorization: Bearer <token>
{
  "flowId": "6543210abcdef",  # Flow ID desde dashboard
  "metadata": {
    "conductor_id": "uuid-123",
    "email": "juan@example.com"
  }
}

# Response
{
  "id": "identity_123",
  "url": "https://signup.metamap.com/verify/identity_123"
}

# 2. Usuario completa verificación en URL
# - Upload INE (frente/reverso)
# - Selfie + liveness check
# - Extracción datos OCR

# 3. Webhook (verification.completed)
POST https://conductores.com/api/v1/conductores/webhook/metamap
{
  "eventName": "verification.completed",
  "resource": "https://api.metamap.com/v2/identities/identity_123"
}

# 4. Obtener resultado
GET /identities/identity_123
{
  "status": "verified",
  "verificationStatus": "approved",
  "fields": {
    "full-name": {"value": "JUAN PEREZ GARCIA"},
    "date-of-birth": {"value": "1990-05-15"},
    "document-number": {"value": "1234567890123"},
    "curp": {"value": "PEGJ900515HDFRRL02"}
  },
  "documentImages": [...]
}
```

### Validaciones Realizadas
```yaml
Documento INE:
  - Autenticidad (anti-spoofing)
  - OCR extracción datos
  - Verificación vs padrón electoral (opcional)

Selfie + Liveness:
  - Face match (INE vs selfie)
  - Liveness detection (no foto de foto)
  - Quality score > 0.7

Datos Extraídos:
  - Nombre completo
  - Fecha de nacimiento
  - CURP
  - Domicilio
  - Vigencia INE
```

---

## 🔌 Integración 4: NEON Bank

### Información General
```yaml
Proveedor: NEON (Banco Digital Brasil/México)
API: NEON Banking API
Versión: v1
Base URL: https://api.neon.com.br/v1
Autenticación: OAuth2 Client Credentials
Uso: Dispersión de créditos (ACH/SPEI)
Límite: $500K MXN por transacción
```

### Autenticación OAuth2
```python
POST /oauth/token
{
  "grant_type": "client_credentials",
  "client_id": "conductores_prod",
  "client_secret": "********",
  "scope": "transfers:write"
}

# Response
{
  "access_token": "eyJ...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### Dispersión de Crédito
```python
# 1. Crear transferencia
POST /transfers
Headers: Authorization: Bearer <token>
{
  "amount": 200000.00,
  "currency": "MXN",
  "destination": {
    "account_number": "012345678901234567",  # CLABE
    "account_type": "checking",
    "bank_code": "012",  # BBVA
    "holder_name": "JUAN PEREZ GARCIA",
    "holder_tax_id": "PEGJ900515ABC"
  },
  "description": "Dispersión Crédito #12345",
  "reference": "CRE-uuid-123"
}

# 2. Webhook (transfer.completed)
POST https://conductores.com/api/v1/creditos/webhook/neon
{
  "event": "transfer.completed",
  "transfer_id": "txn_789",
  "status": "completed",
  "completed_at": "2024-01-15T14:30:00Z"
}
```

### Tiempos de Procesamiento
```yaml
SPEI (Mismo banco): 1-2 horas
SPEI (Otro banco): 24-48 horas
Límite diario: $2M MXN
Horario: 24/7 (SPEI 3.0)
```

---

## 🔌 Integración 5: Odoo ERP

> Notas operativas completas (módulos, productos, journals, parámetros) en `ANEXO_ODOO_SETUP.md`.

### Información General
```yaml
Proveedor: Odoo S.A.
API: XML-RPC
Versión: 16 Community
Base URL: https://conductores.odoo.com
Módulos: CRM, Account, l10n_mx (CFDI 4.0)
Uso: CRM + Facturación electrónica
```

### Autenticación XML-RPC
```python
import xmlrpc.client

# 1. Authenticate
common = xmlrpc.client.ServerProxy(
    'https://conductores.odoo.com/xmlrpc/2/common'
)
uid = common.authenticate(
    'conductores_db',    # Database
    'admin',             # Username
    'password',          # Password
    {}                   # User agent
)

# 2. Get models
models = xmlrpc.client.ServerProxy(
    'https://conductores.odoo.com/xmlrpc/2/object'
)
```

### Sincronización CRM
```python
# Crear/actualizar contacto
partner_id = models.execute_kw(
    'conductores_db', uid, 'password',
    'res.partner', 'create', [{
        'name': 'Juan Pérez',
        'email': 'juan@example.com',
        'phone': '+5215512345678',
        'vat': 'PEGJ900515ABC',  # RFC
        'x_conductor_id': 'uuid-123',  # Campo custom
        'is_company': False
    }]
)

# Crear oportunidad CRM
opportunity_id = models.execute_kw(
    'conductores_db', uid, 'password',
    'crm.lead', 'create', [{
        'name': 'Solicitud Crédito $200K',
        'partner_id': partner_id,
        'expected_revenue': 200000.00,
        'probability': 70,
        'stage_id': 1,  # Nuevo
        'x_score_hase': 85
    }]
)
```

### Facturación CFDI 4.0
```python
# Crear factura
invoice_id = models.execute_kw(
    'conductores_db', uid, 'password',
    'account.move', 'create', [{
        'partner_id': partner_id,
        'move_type': 'out_invoice',
        'invoice_date': '2024-01-15',
        'l10n_mx_edi_payment_method_id': 1,  # PUE
        'l10n_mx_edi_usage': 'G03',  # Gastos en general
        'invoice_line_ids': [(0, 0, {
            'product_id': 1,  # Servicio Intereses
            'name': 'Intereses Crédito Automotriz',
            'quantity': 1,
            'price_unit': 8567.00,
            'tax_ids': [(6, 0, [1])]  # IVA 16%
        })]
    }]
)

# Timbrar (envía al PAC)
models.execute_kw(
    'conductores_db', uid, 'password',
    'account.move', 'action_post', [[invoice_id]]
)

# Obtener XML + PDF
invoice_data = models.execute_kw(
    'conductores_db', uid, 'password',
    'account.move', 'read', [[invoice_id]], {
        'fields': ['l10n_mx_edi_cfdi_uuid', 'l10n_mx_edi_cfdi']
    }
)
```

### BFF ↔ Odoo (NestJS)

> Fuente: `pwa_angular/bff/src/odoo/*.ts` + `PWA - Integración con Odoo.docx`.

- **Configuración:**
  - Variables: `ODOO_BASE_URL`, `ODOO_API_KEY`, `ODOO_STAGING_URL` (ver `production-endpoints.config.ts`).
  - `OdooModule` se carga en el BFF (`app.module.ts`) con controladora `api/bff/odoo/quotes`.
  - Se usa API Key en encabezado `X-Odoo-Key` para llamadas REST wrappers y XML-RPC para operaciones contables.

- **DTOs (bff/src/odoo/dto.ts):**

| DTO | Campos | Validaciones |
|-----|--------|--------------|
| `CreateDraftDto` | `clientId?`, `market?`, `notes?`, `meta?` | `@IsString` / `@IsOptional` para todos los campos; permite adjuntar payloads del cotizador. |
| `AddLineDto` | `sku?`, `oem?`, `name` (requerido), `equivalent?`, `qty?`, `unitPrice`, `currency?`, `meta?` | `qty` y `unitPrice` validan `@IsNumber` + `@Min`; default `currency=MXN`. |

- **Endpoints expuestos por el BFF:**

```http
POST /api/bff/odoo/quotes
Authorization: Bearer <BFF_API_KEY>
Content-Type: application/json

{
  "clientId": "uuid-cliente",
  "market": "EdoMex",
  "notes": "Paquete productivo obligatorio",
  "meta": {
    "hu": "HU-08",
    "advisor": "asesor@conductores.lat"
  }
}

→ { "quoteId": "Q-mlg34p", "number": "SO51234" }

POST /api/bff/odoo/quotes/Q-mlg34p/lines
{
  "sku": "H6C-BASE",
  "name": "Vagoneta H6C 19p",
  "qty": 1,
  "unitPrice": 799000,
  "currency": "MXN"
}

→ { "quoteId": "Q-mlg34p", "lineId": "L-rl45ht", "total": 799000, "currency": "MXN" }
```

- **Lógica de servicio (`OdooService`):** mantiene `drafts` en memoria para demo/offline y, cuando `ODOO_API_KEY` está activo, reenvía las solicitudes a Odoo (XML-RPC `sale.order`/`sale.order.line`). Cualquier creación de línea recalcula el total y expone la suma al frontend.

- **Webhooks y reintentos:**
  - `POST /api/bff/webhooks/odoo` recibe eventos `model`/`method` y los replica en NEON/Airtable.
  - `PaymentsService` permite configurar `odoo_webhook_url` y `odoo_auth_token` para que los cobros enviados por Conekta lleguen a `sale.order`/`account.move` mediante el `webhookRetryService` (cola con DLQ y métricas).

Esta capa BFF abstrae la autenticación, agrupa DTOs amigables para Angular y mantiene resiliencia mediante rate limiting (100 req/min) y políticas de reintento.

---

## 🔌 Integración 6: OpenAI (GPT-4)

### Información General
```yaml
Proveedor: OpenAI
API: OpenAI API
Versión: v1
Base URL: https://api.openai.com/v1
Costo: ~$0.01 USD por 1K tokens
Uso: Chatbot atención + Embeddings RAG
```

### Chat Completion
```python
import openai

response = openai.ChatCompletion.create(
    model="gpt-4-turbo-preview",
    messages=[
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": "¿Cómo solicito una pausa?"}
    ],
    temperature=0.7,
    max_tokens=500
)

SYSTEM_PROMPT = """
Eres un asistente de Conductores del Mundo, plataforma de créditos
automotrices para conductores de Uber/Didi en México.

Información clave:
- Tasas: 14-18% anual
- Pausas: 2-3 al año
- Score HASE: evalúa telemetría GPS
- Soporte: lun-vie 9am-6pm

Tono: amable, profesional, conciso.
"""
```

### Embeddings para RAG
```python
# 1. Crear embeddings de documentación
docs = [
    "Las pausas de pago permiten...",
    "El Motor HASE evalúa...",
    "Para aprobar un crédito se requiere..."
]

embeddings = []
for doc in docs:
    response = openai.Embedding.create(
        model="text-embedding-3-small",
        input=doc
    )
    embeddings.append(response['data'][0]['embedding'])

# 2. Almacenar en Pinecone (ver siguiente integración)
```

---

## 🔌 Integración 7: Pinecone Vector DB

### Información General
```yaml
Proveedor: Pinecone Systems
API: Pinecone API
Base URL: https://<index-name>-<project-id>.svc.pinecone.io
Plan: Starter ($70/mes - 10K vectores)
Uso: RAG context para chatbot
```

### Setup & Upsert
```python
import pinecone

# 1. Initialize
pinecone.init(
    api_key="abc123...",
    environment="us-west1-gcp"
)

# 2. Create index (solo primera vez)
pinecone.create_index(
    name="conductores-kb",
    dimension=1536,  # text-embedding-3-small
    metric="cosine"
)

# 3. Upsert vectors
index = pinecone.Index("conductores-kb")
index.upsert(vectors=[
    ("doc-001", embedding_1, {"text": "Las pausas...", "category": "pausas"}),
    ("doc-002", embedding_2, {"text": "Motor HASE...", "category": "scoring"}),
    # ... 10K docs
])
```

### Query (Búsqueda Semántica)
```python
# 1. Usuario pregunta
user_query = "¿Cómo solicito una pausa?"

# 2. Embedding de query
query_embedding = openai.Embedding.create(
    model="text-embedding-3-small",
    input=user_query
)['data'][0]['embedding']

# 3. Buscar vectores similares
results = index.query(
    vector=query_embedding,
    top_k=3,
    include_metadata=True
)

# 4. Construir contexto para GPT-4
context = "\n\n".join([match['metadata']['text'] for match in results['matches']])

# 5. Chat con contexto
response = openai.ChatCompletion.create(
    model="gpt-4-turbo-preview",
    messages=[
        {"role": "system", "content": f"Contexto:\n{context}\n\n{SYSTEM_PROMPT}"},
        {"role": "user", "content": user_query}
    ]
)
```

---

## 🔌 Integración 8: SINOSURE

### Información General
```yaml
Proveedor: China Export & Credit Insurance Corp.
API: Custom API (no pública)
Autenticación: Mutual TLS + firma digital
Línea: $10M USD seguro de crédito
Cobertura: Hasta 90% saldo insoluto
Uso: Reporte cartera + siniestros
```

### Flujo Mensual
```python
# 1. Generar reporte de cartera (día 1 de mes)
portfolio = {
    "report_date": "2024-01-01",
    "total_credits": 500,
    "total_exposure": 100_000_000.00,  # MXN
    "by_tier": {
        "AAA": {"count": 200, "exposure": 50_000_000.00},
        "AA":  {"count": 150, "exposure": 30_000_000.00},
        "A":   {"count": 100, "exposure": 15_000_000.00},
        "B":   {"count": 50,  "exposure": 5_000_000.00}
    },
    "late_credits": 15,
    "default_credits": 2
}

# 2. Firmar con certificado
signature = sign_with_cert(portfolio, SINOSURE_CERT)

# 3. Enviar reporte
POST https://api.sinosure.com.cn/reports
Headers:
  X-Client-ID: conductores-mx
  X-Signature: <signature>
Body: <portfolio>

# 4. Reporte siniestros (si hay defaults > 90 días)
claim = {
    "credit_id": "uuid-123",
    "borrower": {...},
    "original_amount": 200_000.00,
    "outstanding_balance": 180_000.00,
    "days_past_due": 95,
    "tier": "AA",
    "claim_amount": 162_000.00  # 90% de 180K
}

POST https://api.sinosure.com.cn/claims
```

### Proceso de Aprobación Claim
```yaml
Día 95+: Reporte default a SINOSURE
Día 100: SINOSURE inicia investigación
Día 120: Aprobación/rechazo claim
Día 130: Pago 90% saldo (si aprobado)
```

---

## 🚀 Siguiente Fase

**→ CORE_FASE5_TESTING.md**
- Estrategia de testing
- Unit, integration, E2E
- Coverage targets
- CI/CD testing pipeline
