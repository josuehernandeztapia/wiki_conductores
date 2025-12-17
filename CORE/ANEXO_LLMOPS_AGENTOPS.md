# ANEXO — LLMOps y AgentOps para Agentes IA (Runbook Operativo)

## Objetivo

Este documento establece las prácticas operativas, pipelines de despliegue, observabilidad y procedimientos de incidentes para los servicios de IA del proyecto (agente_postventa RAG y avi_lab Voice Pattern), complementando `ANEXO_IA_IMPLEMENTACIONES_EXTERNAS.md`.

---

## 1. CONTAINERIZACIÓN (Docker)

### 1.1 Arquitectura de Contenedores

```yaml
Servicios IA:
  agente_postventa:
    image: agente-postventa:latest
    base: python:3.11-slim
    dependencies: fastapi, uvicorn, pinecone-client, openai, langchain
    ports: 8000
    health: /health

  avi_lab:
    image: avi-lab:latest
    base: node:20-alpine
    framework: Angular 18
    ports: 4200
    serve: nginx (producción)

Infraestructura compartida:
  redis:
    image: redis:7-alpine
    purpose: Cache + session + rate limiting

  postgres:
    provider: NEON (externo)
    connection: via DATABASE_URL
```

### 1.2 Dockerfile Best Practices

**agente_postventa/Dockerfile:**
```dockerfile
FROM python:3.11-slim as builder
WORKDIR /app
RUN pip install --no-cache-dir poetry
COPY pyproject.toml poetry.lock ./
RUN poetry export -f requirements.txt --output requirements.txt --without-hashes

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY ./app ./app
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**avi_lab/Dockerfile (producción):**
```dockerfile
FROM node:20-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build -- --configuration production

FROM nginx:alpine
COPY --from=builder /app/dist/avi-lab /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
HEALTHCHECK CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1
CMD ["nginx", "-g", "daemon off;"]
```

### 1.3 Docker Compose (Local/Staging)

```yaml
# docker-compose.yml
version: '3.8'

services:
  agente-postventa:
    build: ./agente_postventa
    ports:
      - "8000:8000"
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - PINECONE_API_KEY=${PINECONE_API_KEY}
      - PINECONE_INDEX=${PINECONE_INDEX}
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=${NEON_DATABASE_URL}
      - TWILIO_ACCOUNT_SID=${TWILIO_ACCOUNT_SID}
      - TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN}
    depends_on:
      - redis
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  redis_data:
```

---

## 2. CI/CD PIPELINES

### 2.1 GitHub Actions Workflow

**agente_postventa/.github/workflows/deploy.yml:**
```yaml
name: Deploy Agente Postventa

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/agente-postventa

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          pip install poetry
          poetry install
      - name: Run tests
        run: poetry run pytest tests/ -v --cov
      - name: Lint
        run: poetry run ruff check .

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Deploy to Fly.io staging
        run: |
          flyctl deploy --app agente-postventa-staging \
            --image ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
      - name: Run smoke tests
        run: |
          curl -f https://agente-postventa-staging.fly.dev/health || exit 1
          curl -f https://agente-postventa-staging.fly.dev/metrics || exit 1
```

### 2.2 Deployment Checklist

**Pre-deployment (staging):**
- [ ] Tests pasan (pytest coverage > 80%)
- [ ] Lint sin errores (ruff check)
- [ ] Variables de entorno configuradas en Fly.io/Railway
- [ ] Secrets actualizados (OPENAI_API_KEY, PINECONE_API_KEY, TWILIO)
- [ ] NEON database staging accesible

**Post-deployment:**
- [ ] Health check responde 200
- [ ] Smoke test: POST /query con pregunta conocida
- [ ] Webhook /twilio/whatsapp recibe test message
- [ ] Logs en CloudWatch/Grafana sin errores críticos
- [ ] Métricas en /metrics muestran 0 errores iniciales

---

## 3. PIPELINES DE DATOS (Vector DB + Knowledge Base)

### 3.1 Ingesta de Documentos (Pinecone)

**Pipeline de vectorización:**
```python
# scripts/ingest_knowledge_base.py
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from pinecone import Pinecone
import os

def ingest_documents(docs_dir: str, index_name: str):
    """
    Ingesta documentos al índice Pinecone

    Args:
        docs_dir: Directorio con archivos .md/.txt de knowledge base
        index_name: Nombre del índice Pinecone (ej. higer-postventa-kb)
    """
    pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
    index = pc.Index(index_name)
    embeddings = OpenAIEmbeddings()

    splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200,
        separators=["\n## ", "\n### ", "\n\n", "\n", " "]
    )

    for filename in os.listdir(docs_dir):
        if not filename.endswith(('.md', '.txt')):
            continue

        with open(os.path.join(docs_dir, filename)) as f:
            content = f.read()

        chunks = splitter.split_text(content)
        vectors = embeddings.embed_documents(chunks)

        # Upsert a Pinecone con metadata
        batch = [
            {
                "id": f"{filename}_{i}",
                "values": vec,
                "metadata": {
                    "text": chunk,
                    "source": filename,
                    "chunk_id": i
                }
            }
            for i, (chunk, vec) in enumerate(zip(chunks, vectors))
        ]
        index.upsert(vectors=batch)

    print(f"✅ Ingested {len(batch)} chunks to {index_name}")
```

**Uso:**
```bash
# Staging
PINECONE_API_KEY=... OPENAI_API_KEY=... \
python scripts/ingest_knowledge_base.py \
  --docs-dir ./knowledge_base \
  --index higer-postventa-staging

# Production
PINECONE_API_KEY=... OPENAI_API_KEY=... \
python scripts/ingest_knowledge_base.py \
  --docs-dir ./knowledge_base \
  --index higer-postventa-prod
```

### 3.2 Actualización de Catálogos (NEON)

**Sincronización de refacciones/fallas:**
```bash
# scripts/sync_catalogs_neon.sh
#!/usr/bin/env bash
set -euo pipefail

# Descarga catálogos desde NEON API
curl -H "x-api-key: $NEON_API_KEY" \
  https://api.neon.com/spare_parts > spare_parts.json

curl -H "x-api-key: $NEON_API_KEY" \
  https://api.neon.com/fault_catalog > fault_catalog.json

# Convierte JSON a texto embedeable
python scripts/json_to_markdown.py spare_parts.json > knowledge_base/spare_parts.md
python scripts/json_to_markdown.py fault_catalog.json > knowledge_base/fault_catalog.md

# Re-ingesta a Pinecone
python scripts/ingest_knowledge_base.py --docs-dir knowledge_base --index $PINECONE_INDEX

echo "✅ Catálogos sincronizados y vectorizados"
```

**Frecuencia recomendada:**
- **Staging:** Diario (cron 2am)
- **Production:** Semanal o bajo demanda (cambios de catálogo)

---

## 4. INTEGRACIÓN WHATSAPP/TWILIO

### 4.1 Webhook Configuration

**Twilio Console Setup:**
1. Comprar número WhatsApp Business (ej. +52 55 1234 5678)
2. Configurar webhook URL: `https://agente-postventa.fly.dev/twilio/whatsapp`
3. Método: POST
4. Content-Type: application/x-www-form-urlencoded
5. Configurar Callback Status: `https://agente-postventa.fly.dev/twilio/status`

**Validación de firma (seguridad):**
```python
from twilio.request_validator import RequestValidator

def validate_twilio_request(request, url: str) -> bool:
    validator = RequestValidator(os.getenv("TWILIO_AUTH_TOKEN"))
    signature = request.headers.get("X-Twilio-Signature", "")
    return validator.validate(url, request.form, signature)
```

### 4.2 Flujo de Mensajes

```
Usuario → WhatsApp → Twilio → POST /twilio/whatsapp
                                  ↓
                          1. Validar firma Twilio
                          2. Extraer From/Body/MediaUrl
                          3. Procesar medios (OCR/transcripción)
                          4. Ejecutar RAG híbrido
                          5. Actualizar caso/memoria
                          6. Responder vía Twilio API
                                  ↓
                          Twilio → WhatsApp → Usuario
```

### 4.3 Manejo de Medios

**Tipos soportados:**
- **Imágenes** (JPEG/PNG): OCR con Tesseract/Vision API
- **Audio** (OGG/MP3): Transcripción con Whisper API
- **Video** (MP4): Extracción de frame + transcripción
- **Documentos** (PDF): Extracción de texto

**Ejemplo procesamiento:**
```python
async def process_media(media_url: str, content_type: str) -> str:
    if content_type.startswith("image/"):
        # OCR
        image = download_media(media_url)
        text = pytesseract.image_to_string(image)
        return f"[OCR] {text}"

    elif content_type.startswith("audio/"):
        # Transcripción Whisper
        audio = download_media(media_url)
        transcript = openai.Audio.transcribe("whisper-1", audio)
        return f"[Audio] {transcript['text']}"

    return "[Media no procesable]"
```

---

## 5. OBSERVABILIDAD

### 5.1 Métricas (Prometheus)

**Endpoint /metrics expuesto por FastAPI:**
```python
from prometheus_client import Counter, Histogram, generate_latest

# Contadores
query_total = Counter("rag_query_total", "Total queries", ["endpoint", "status"])
query_duration = Histogram("rag_query_duration_seconds", "Query latency")

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type="text/plain")
```

**Métricas clave:**
- `rag_query_total{endpoint="/query_hybrid", status="success"}` → Total queries exitosas
- `rag_query_duration_seconds_bucket` → Latencia p50/p95/p99
- `pinecone_search_duration_seconds` → Tiempo de búsqueda vectorial
- `openai_api_errors_total` → Errores de OpenAI API
- `webhook_messages_total{provider="twilio"}` → Mensajes WhatsApp procesados

### 5.2 Logs Estructurados

**Configuración logging:**
```python
import structlog

logger = structlog.get_logger()
logger.bind(service="agente_postventa", environment="production")

# Uso
logger.info(
    "rag_query_executed",
    query=query,
    contact_id=contact_id,
    duration_ms=duration,
    sources_count=len(sources)
)
```

**Logs críticos:**
- `rag_query_executed` → Cada query con contexto
- `webhook_received` → Mensajes WhatsApp entrantes
- `openai_api_error` → Fallos de OpenAI (rate limit, timeout)
- `pinecone_error` → Errores de vector DB
- `case_created` → Nuevo caso/ticket abierto

### 5.3 Dashboards (Grafana)

**Dashboard recomendado:**
- **Panel 1:** Query rate (queries/min)
- **Panel 2:** Latencia p50/p95/p99
- **Panel 3:** Error rate (%)
- **Panel 4:** OpenAI API calls & costs
- **Panel 5:** Pinecone search latency
- **Panel 6:** WhatsApp messages in/out

**Alertas:**
- Error rate > 5% durante 5 min → PagerDuty
- Latencia p95 > 3s → Slack #alerts
- OpenAI API errors > 10/min → Email equipo IA

---

## 6. SEGURIDAD

### 6.1 Autenticación y Autorización

**Endpoints públicos (webhook):**
- `/twilio/whatsapp` → Validación de firma Twilio (HMAC)

**Endpoints internos (protegidos):**
- `/query`, `/query_hybrid` → API Key (header `x-api-key`)
- `/admin/*` → JWT token + role=admin

**Implementación API Key:**
```python
from fastapi import Security, HTTPException
from fastapi.security import APIKeyHeader

api_key_header = APIKeyHeader(name="x-api-key")

async def verify_api_key(api_key: str = Security(api_key_header)):
    if api_key != os.getenv("INTERNAL_API_KEY"):
        raise HTTPException(status_code=403, detail="Invalid API key")
```

### 6.2 Rate Limiting (Redis)

```python
from fastapi_limiter import FastAPILimiter
from fastapi_limiter.depends import RateLimiter

# Startup
@app.on_event("startup")
async def startup():
    redis = await aioredis.from_url(os.getenv("REDIS_URL"))
    await FastAPILimiter.init(redis)

# Endpoint con rate limit
@app.post("/query", dependencies=[Depends(RateLimiter(times=10, seconds=60))])
async def query(q: QueryRequest):
    ...
```

**Límites recomendados:**
- `/query_hybrid`: 10 req/min por contact_id
- `/twilio/whatsapp`: 100 req/min global
- `/admin/*`: 50 req/min por API key

### 6.3 Manejo de Secretos

**Variables sensibles (NUNCA en código):**
- `OPENAI_API_KEY`
- `PINECONE_API_KEY`
- `TWILIO_AUTH_TOKEN`
- `NEON_DATABASE_URL`
- `INTERNAL_API_KEY`

**Gestión:**
- **Local/Staging:** `.env` (git-ignored) + direnv
- **Production:** Fly.io secrets / Railway vars / AWS Secrets Manager

```bash
# Fly.io
flyctl secrets set OPENAI_API_KEY=sk-... --app agente-postventa-prod
flyctl secrets set PINECONE_API_KEY=... --app agente-postventa-prod
```

---

## 7. QA Y TESTING

### 7.1 Tipos de Tests

**Unit tests (pytest):**
```python
# tests/test_rag.py
def test_query_basic():
    response = client.post("/query", json={"query": "precio motor A3000"})
    assert response.status_code == 200
    assert "A3000" in response.json()["answer"]

def test_rate_limit():
    for _ in range(11):
        response = client.post("/query", json={"query": "test"})
    assert response.status_code == 429  # Too Many Requests
```

**Integration tests:**
```python
# tests/test_integrations.py
def test_pinecone_search():
    results = pinecone_client.query(vector=[0.1]*1536, top_k=5)
    assert len(results["matches"]) > 0

def test_openai_embedding():
    embedding = openai.Embedding.create(input="test", model="text-embedding-3-small")
    assert len(embedding["data"][0]["embedding"]) == 1536
```

**E2E tests (simulación WhatsApp):**
```python
def test_whatsapp_flow():
    # Simular webhook Twilio
    payload = {
        "From": "whatsapp:+525512345678",
        "Body": "Necesito precio del motor A3000"
    }
    response = client.post("/twilio/whatsapp", data=payload)
    assert response.status_code == 200
    assert "A3000" in response.text  # Respuesta incluye info del motor
```

### 7.2 Evaluación de Calidad de Respuestas

**Framework de evaluación:**
```python
# scripts/eval_rag_quality.py
from ragas import evaluate
from ragas.metrics import faithfulness, answer_relevancy

test_cases = [
    {
        "question": "¿Cuánto cuesta el motor A3000?",
        "expected_answer": "$45,000 MXN",
        "expected_sources": ["spare_parts.md"]
    },
    # ... más casos
]

# Ejecutar evaluación
results = evaluate(test_cases, metrics=[faithfulness, answer_relevancy])
print(f"Faithfulness: {results['faithfulness']:.2f}")
print(f"Answer Relevancy: {results['answer_relevancy']:.2f}")
```

**Criterios de calidad:**
- **Faithfulness** (fidelidad a fuentes): > 0.8
- **Answer Relevancy** (relevancia): > 0.75
- **Latencia p95**: < 3s
- **Error rate**: < 2%

---

## 8. RUNBOOKS OPERATIVOS

### 8.1 Incidente: Alta Latencia (p95 > 5s)

**Diagnóstico:**
1. Verificar dashboard Grafana → identificar endpoint lento
2. Revisar logs con filtro `duration_ms > 5000`
3. Verificar Pinecone status: https://status.pinecone.io/
4. Verificar OpenAI API status: https://status.openai.com/

**Mitigación:**
```bash
# 1. Revisar logs últimos 15min
flyctl logs --app agente-postventa-prod | grep "duration_ms" | sort -t':' -k5 -n

# 2. Verificar health Pinecone
curl https://controller.$PINECONE_ENV.pinecone.io/health

# 3. Si Pinecone lento → fallback a BM25 solo
flyctl secrets set FALLBACK_MODE=bm25_only --app agente-postventa-prod
flyctl deploy --strategy immediate

# 4. Escalar instancias (si es carga)
flyctl scale count 3 --app agente-postventa-prod
```

**Postmortem:**
- Documentar causa raíz (Pinecone latency spike, OpenAI rate limit, etc.)
- Ajustar timeouts o implementar circuit breaker

### 8.2 Incidente: OpenAI Rate Limit

**Síntomas:**
- Logs: `openai_api_error: rate_limit_exceeded`
- Métricas: spike en `openai_api_errors_total`

**Mitigación inmediata:**
```bash
# 1. Activar modo degradado (respuestas pre-cacheadas)
flyctl secrets set DEGRADED_MODE=true --app agente-postventa-prod

# 2. Reducir concurrencia de requests
# En código: limiter de semáforos asyncio
import asyncio
sem = asyncio.Semaphore(5)  # Max 5 requests concurrentes a OpenAI

# 3. Contactar OpenAI para aumentar quota
```

**Prevención:**
- Implementar exponential backoff con tenacity
- Cache de embeddings frecuentes en Redis
- Monitorear usage diario vs quota

### 8.3 Incidente: Webhook Twilio No Responde

**Síntomas:**
- Usuarios reportan mensajes sin respuesta
- Logs: no aparecen requests en `/twilio/whatsapp`

**Diagnóstico:**
1. Verificar Twilio Console → Debugger (errores de webhook)
2. Verificar health del servicio: `curl https://agente-postventa.fly.dev/health`
3. Verificar logs de certificado SSL (expired?)

**Mitigación:**
```bash
# 1. Verificar servicio activo
flyctl status --app agente-postventa-prod

# 2. Si servicio caído → restart
flyctl apps restart agente-postventa-prod

# 3. Verificar endpoint manualmente
curl -X POST https://agente-postventa.fly.dev/twilio/whatsapp \
  -d "From=whatsapp:+5215512345678" \
  -d "Body=test"

# 4. Si persiste → rollback a versión anterior
flyctl releases list --app agente-postventa-prod
flyctl releases rollback <version> --app agente-postventa-prod
```

### 8.4 Incidente: Respuestas Incorrectas (Quality Degradation)

**Síntomas:**
- Usuarios reportan respuestas no relevantes
- Métricas: aumento en feedback negativo

**Diagnóstico:**
1. Revisar últimos queries en logs:
   ```bash
   flyctl logs --app agente-postventa-prod | grep "rag_query_executed" | tail -50
   ```
2. Verificar índice Pinecone actualizado:
   ```bash
   python scripts/check_index_stats.py --index higer-postventa-prod
   ```
3. Ejecutar eval suite:
   ```bash
   python scripts/eval_rag_quality.py --env prod
   ```

**Mitigación:**
```bash
# 1. Re-ingestar knowledge base si desactualizada
python scripts/ingest_knowledge_base.py \
  --docs-dir ./knowledge_base \
  --index higer-postventa-prod \
  --force

# 2. Ajustar parámetros de búsqueda (si relevancy baja)
# top_k: 5 → 10 (más contexto)
# similarity threshold: 0.7 → 0.65 (menos restrictivo)

# 3. Rollback a modelo anterior si cambio reciente
git checkout <commit-hash> app/rag/retriever.py
flyctl deploy --app agente-postventa-prod
```

---

## 9. MONITOREO DE COSTOS

### 9.1 Tracking de Uso

**OpenAI API:**
- Embedding model (`text-embedding-3-small`): $0.02/1M tokens
- Chat model (`gpt-4-turbo`): $10/1M input tokens, $30/1M output tokens

**Estimación mensual (1000 queries/día):**
```
Embeddings: 1000 queries * 200 tokens * 30 días = 6M tokens → $0.12
Chat: 1000 queries * (500 input + 300 output) * 30 días = 24M tokens → $456
Total: ~$460/mes
```

**Pinecone:**
- Serverless: $0.0001/query + $0.15/GB storage
- Pod-based (p1.x1): $70/mes

**Recomendación:** Usar Pinecone Serverless para staging, Pod para prod (costo predecible).

### 9.2 Optimización

**Reducción de costos OpenAI:**
1. **Cache de embeddings** frecuentes en Redis (TTL 7 días)
2. **Prompt compression:** Reducir contexto de 3000 → 1500 tokens
3. **Model downgrade** para queries simples: `gpt-4-turbo` → `gpt-3.5-turbo` (10x más barato)

**Reducción de costos Pinecone:**
1. **Filtros metadata** antes de query (reduce búsqueda)
2. **top_k dinámico:** preguntas simples k=3, complejas k=10
3. **Borrar vectores obsoletos** (knowledge base vieja)

---

## 10. CHECKLIST PRE-PRODUCCIÓN

### Infraestructura
- [ ] Docker images buildeadas y pusheadas a registry
- [ ] Servicios desplegados en Fly.io/Railway (staging + prod)
- [ ] Redis configurado y accesible
- [ ] NEON database prod con permisos correctos

### Configuración
- [ ] Variables de entorno prod configuradas
- [ ] Secrets rotados (keys diferentes staging/prod)
- [ ] Rate limits configurados
- [ ] Webhooks Twilio apuntando a prod

### Datos
- [ ] Knowledge base actualizada en Pinecone prod
- [ ] Catálogos NEON sincronizados
- [ ] Índices Pinecone con metadata correcta
- [ ] BM25 index construido (fallback)

### Observabilidad
- [ ] Prometheus scraping /metrics
- [ ] Grafana dashboard configurado
- [ ] Alertas en PagerDuty/Slack
- [ ] Logs centralizados en CloudWatch

### Testing
- [ ] Unit tests > 80% coverage
- [ ] Integration tests pasan
- [ ] E2E WhatsApp flow validado
- [ ] Eval suite: faithfulness > 0.8, relevancy > 0.75

### Seguridad
- [ ] API keys rotadas
- [ ] Twilio signature validation activa
- [ ] Rate limiting en endpoints públicos
- [ ] Secrets en vault (no en código)

### Documentación
- [ ] Runbooks actualizados
- [ ] Postmortems de incidentes staging documentados
- [ ] Diagramas de arquitectura actualizados
- [ ] README con instrucciones de despliegue

---

## Referencias

- **Repos IA:** Ver `ANEXO_IA_IMPLEMENTACIONES_EXTERNAS.md`
- **Blueprint RAG:** `IDEAS/IDEAS_18_AGENTE_POSTVENTA_RAG.md`
- **Checklist operativo:** `IDEAS/IDEAS_99_CIERRE_RAG_POSTVENTA.md`
- **Voice Pattern:** `LOGICA_MATEMATICA.md` sección 6
- **HU24/HU25:** `CORE/CORE_FASE10_PILOTO_OPERATIVO.md`
