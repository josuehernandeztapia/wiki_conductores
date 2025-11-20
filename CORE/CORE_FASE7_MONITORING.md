# CORE FASE 7: MONITORING & OBSERVABILITY

## 🎯 Objetivo
Implementar observabilidad completa del sistema con métricas técnicas y de negocio, alertas inteligentes, y dashboards en tiempo real.

---

## 📊 Stack de Observabilidad

```
Metrics:      Prometheus + Grafana
Logs:         CloudWatch Logs + ELK Stack
Traces:       OpenTelemetry + Jaeger
Errors:       Sentry
Uptime:       UptimeRobot
Business:     Metabase + Custom Dashboard
```

---

## 📈 Métricas Técnicas (Prometheus)

### 1. API Metrics

```python
# src/main.py
from prometheus_client import Counter, Histogram, Gauge
from prometheus_fastapi_instrumentator import Instrumentator

# Request metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint'],
    buckets=[0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0]
)

# Database metrics
db_query_duration_seconds = Histogram(
    'db_query_duration_seconds',
    'Database query latency',
    ['table', 'operation'],
    buckets=[0.001, 0.01, 0.05, 0.1, 0.5, 1.0]
)

db_connections_active = Gauge(
    'db_connections_active',
    'Active database connections'
)

# Redis metrics
redis_commands_total = Counter(
    'redis_commands_total',
    'Total Redis commands',
    ['command', 'status']
)

# Integration metrics
integration_api_calls_total = Counter(
    'integration_api_calls_total',
    'External API calls',
    ['integration', 'endpoint', 'status']
)

integration_api_duration_seconds = Histogram(
    'integration_api_duration_seconds',
    'External API latency',
    ['integration', 'endpoint']
)

# Instrumentar FastAPI automáticamente
Instrumentator().instrument(app).expose(app, endpoint="/metrics")
```

### 2. Business Metrics

```python
# Custom business metrics
from prometheus_client import Counter, Gauge

# Applications
applications_submitted_total = Counter(
    'applications_submitted_total',
    'Total applications submitted'
)

applications_approved_total = Counter(
    'applications_approved_total',
    'Total applications approved',
    ['sinosure_tier']
)

applications_rejected_total = Counter(
    'applications_rejected_total',
    'Total applications rejected',
    ['reason']
)

# Credits
credits_disbursed_total = Counter(
    'credits_disbursed_total',
    'Total credits disbursed'
)

credits_disbursed_amount_mxn = Counter(
    'credits_disbursed_amount_mxn',
    'Total amount disbursed (MXN)'
)

credits_active_count = Gauge(
    'credits_active_count',
    'Active credits count'
)

# Payments
payments_processed_total = Counter(
    'payments_processed_total',
    'Total payments processed',
    ['status', 'method']
)

payments_late_count = Gauge(
    'payments_late_count',
    'Late payments count',
    ['level']  # late_1_7_days, late_8_15_days, etc.
)

# Motor HASE
hase_scores_calculated_total = Counter(
    'hase_scores_calculated_total',
    'HASE scores calculated'
)

hase_score_distribution = Histogram(
    'hase_score_distribution',
    'HASE score distribution',
    buckets=[0, 50, 60, 70, 75, 80, 85, 90, 95, 100]
)
```

### 3. Prometheus Config

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'conductores-backend'
    static_configs:
      - targets: ['backend:8000']
    metrics_path: '/metrics'

  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['postgres-exporter:9187']

  - job_name: 'redis-exporter'
    static_configs:
      - targets: ['redis-exporter:9121']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
```

---

## 📋 Logs Centralizados

### CloudWatch Logs

```python
# src/utils/logging_config.py
import logging
import watchtower

# CloudWatch handler
cloudwatch_handler = watchtower.CloudWatchLogHandler(
    log_group='/aws/ecs/conductores-backend',
    stream_name='application',
    send_interval=10,
    create_log_group=False
)

# Formato estructurado (JSON)
import json_log_formatter

formatter = json_log_formatter.JSONFormatter()
cloudwatch_handler.setFormatter(formatter)

# Logger configuration
logger = logging.getLogger('conductores')
logger.setLevel(logging.INFO)
logger.addHandler(cloudwatch_handler)

# Usage
logger.info('Application submitted', extra={
    'conductor_id': 'uuid-123',
    'monto_solicitado': 250000,
    'score_hase': 85
})
```

### Log Levels Strategy

```python
# ERROR: Requires immediate attention
logger.error('Payment processing failed', extra={
    'pago_id': 'uuid-456',
    'error': str(e),
    'credito_id': 'uuid-789'
})

# WARNING: Potential issues
logger.warning('Geotab API slow response', extra={
    'duration_ms': 3500,
    'endpoint': '/trips'
})

# INFO: Business events
logger.info('Credit approved', extra={
    'credito_id': 'uuid-123',
    'monto': 200000,
    'tier': 'AAA'
})

# DEBUG: Development only
logger.debug('HASE features extracted', extra={
    'features_count': 152,
    'conductor_id': 'uuid-123'
})
```

---

## 🔍 Distributed Tracing (OpenTelemetry)

```python
# src/main.py
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Setup tracer
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# Jaeger exporter
jaeger_exporter = JaegerExporter(
    agent_host_name="jaeger",
    agent_port=6831,
)

trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(jaeger_exporter)
)

# Auto-instrument
FastAPIInstrumentor.instrument_app(app)
SQLAlchemyInstrumentor().instrument(engine=engine)
RedisInstrumentor().instrument(redis_client=redis_client)

# Manual tracing
@router.post("/applications/submit")
async def submit_application(request: ApplicationCreate):
    with tracer.start_as_current_span("submit_application") as span:
        span.set_attribute("conductor_id", str(request.conductor_id))
        span.set_attribute("monto", float(request.monto_solicitado))

        # Span anidado para Motor HASE
        with tracer.start_as_current_span("hase_scoring"):
            score_result = await motor_hase.score_conductor(...)
            span.set_attribute("score_hase", score_result['score'])

        return result
```

---

## 🚨 Alertas Inteligentes

### Alertmanager Configuration

```yaml
# alertmanager.yml
global:
  slack_api_url: 'https://hooks.slack.com/services/...'

route:
  group_by: ['alertname', 'severity']
  group_wait: 10s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'slack-critical'

  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-oncall'
      continue: true

    - match:
        severity: warning
      receiver: 'slack-warnings'

receivers:
  - name: 'slack-critical'
    slack_configs:
      - channel: '#conductores-alerts'
        title: '🔴 {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: 'pagerduty-oncall'
    pagerduty_configs:
      - service_key: '...'

  - name: 'slack-warnings'
    slack_configs:
      - channel: '#conductores-warnings'
```

### Prometheus Alert Rules

```yaml
# alerts.yml
groups:
  - name: api_alerts
    interval: 30s
    rules:
      # High error rate
      - alert: HighErrorRate
        expr: |
          (
            sum(rate(http_requests_total{status=~"5.."}[5m]))
            /
            sum(rate(http_requests_total[5m]))
          ) > 0.05
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High error rate (> 5%)"
          description: "Error rate is {{ $value | humanizePercentage }}"

      # High latency
      - alert: HighLatency
        expr: |
          histogram_quantile(0.95,
            rate(http_request_duration_seconds_bucket[5m])
          ) > 1.0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High API latency (p95 > 1s)"
          description: "p95 latency: {{ $value }}s"

      # Database connection pool exhaustion
      - alert: DatabaseConnectionPoolExhausted
        expr: db_connections_active / db_connections_max > 0.9
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Database connection pool exhausted"
          description: "{{ $value | humanizePercentage }} connections in use"

  - name: business_alerts
    interval: 1m
    rules:
      # Approval rate drop
      - alert: LowApprovalRate
        expr: |
          (
            sum(increase(applications_approved_total[1h]))
            /
            sum(increase(applications_submitted_total[1h]))
          ) < 0.30
        for: 30m
        labels:
          severity: warning
        annotations:
          summary: "Approval rate dropped below 30%"
          description: "Only {{ $value | humanizePercentage }} applications approved in last hour"

      # High late payments
      - alert: HighLatePayments
        expr: |
          sum(payments_late_count{level="late_16_30_days"}) > 50
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "High number of late payments (16-30 days)"
          description: "{{ $value }} payments are 16-30 days late"

      # Integration downtime
      - alert: GeotabAPIDown
        expr: |
          sum(rate(integration_api_calls_total{integration="geotab",status="error"}[5m]))
          /
          sum(rate(integration_api_calls_total{integration="geotab"}[5m]))
          > 0.5
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Geotab API experiencing high error rate"
          description: "{{ $value | humanizePercentage }} error rate"

      # No disbursements today
      - alert: NoDisbursementsToday
        expr: |
          increase(credits_disbursed_total[24h]) == 0
        labels:
          severity: warning
        annotations:
          summary: "No credit disbursements in last 24 hours"
          description: "Potential pipeline issue"
```

---

## 📊 Dashboards Grafana

### 1. API Health Dashboard

```json
{
  "dashboard": {
    "title": "API Health",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [{
          "expr": "sum(rate(http_requests_total[5m])) by (method, endpoint)"
        }],
        "type": "graph"
      },
      {
        "title": "Error Rate",
        "targets": [{
          "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m]))"
        }],
        "type": "graph",
        "alert": {
          "threshold": 0.05
        }
      },
      {
        "title": "Latency (p50, p95, p99)",
        "targets": [
          {
            "expr": "histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "p50"
          },
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "p95"
          },
          {
            "expr": "histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "p99"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Database Query Duration",
        "targets": [{
          "expr": "histogram_quantile(0.95, rate(db_query_duration_seconds_bucket[5m])) by (table)"
        }],
        "type": "graph"
      }
    ]
  }
}
```

### 2. Business Metrics Dashboard

```json
{
  "dashboard": {
    "title": "Business Metrics",
    "panels": [
      {
        "title": "Applications Today",
        "targets": [{
          "expr": "increase(applications_submitted_total[24h])"
        }],
        "type": "stat",
        "unit": "short"
      },
      {
        "title": "Approval Rate",
        "targets": [{
          "expr": "sum(increase(applications_approved_total[24h])) / sum(increase(applications_submitted_total[24h]))"
        }],
        "type": "gauge",
        "unit": "percentunit"
      },
      {
        "title": "Credits Disbursed (MXN)",
        "targets": [{
          "expr": "increase(credits_disbursed_amount_mxn[24h])"
        }],
        "type": "stat",
        "unit": "currencyMXN"
      },
      {
        "title": "HASE Score Distribution",
        "targets": [{
          "expr": "sum(hase_score_distribution_bucket) by (le)"
        }],
        "type": "heatmap"
      },
      {
        "title": "Late Payments by Level",
        "targets": [{
          "expr": "sum(payments_late_count) by (level)"
        }],
        "type": "graph"
      },
      {
        "title": "Active Credits by Tier",
        "targets": [{
          "expr": "sum(credits_active_count) by (sinosure_tier)"
        }],
        "type": "piechart"
      }
    ]
  }
}
```

### 3. Integration Health Dashboard

```json
{
  "dashboard": {
    "title": "Integrations Health",
    "panels": [
      {
        "title": "API Call Rate by Integration",
        "targets": [{
          "expr": "sum(rate(integration_api_calls_total[5m])) by (integration)"
        }],
        "type": "graph"
      },
      {
        "title": "Integration Error Rate",
        "targets": [{
          "expr": "sum(rate(integration_api_calls_total{status=\"error\"}[5m])) by (integration) / sum(rate(integration_api_calls_total[5m])) by (integration)"
        }],
        "type": "graph"
      },
      {
        "title": "Integration Latency",
        "targets": [{
          "expr": "histogram_quantile(0.95, rate(integration_api_duration_seconds_bucket[5m])) by (integration)"
        }],
        "type": "graph"
      }
    ]
  }
}
```

---

## 🐛 Error Tracking (Sentry)

```python
# src/main.py
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

sentry_sdk.init(
    dsn="https://...@sentry.io/...",
    environment="production",
    traces_sample_rate=0.1,  # 10% de traces
    integrations=[
        FastApiIntegration(),
        SqlalchemyIntegration(),
    ],
    before_send=filter_sensitive_data,
)

def filter_sensitive_data(event, hint):
    """Remove PII from Sentry events"""
    if 'request' in event:
        if 'data' in event['request']:
            # Ofuscar passwords, tokens
            if 'password' in event['request']['data']:
                event['request']['data']['password'] = '[FILTERED]'

    return event

# Custom context
from sentry_sdk import set_context, set_user

@app.middleware("http")
async def add_sentry_context(request: Request, call_next):
    # User context
    if user := get_current_user_optional(request):
        set_user({
            "id": str(user.id),
            "email": user.email
        })

    # Custom context
    set_context("request_info", {
        "path": request.url.path,
        "method": request.method,
        "user_agent": request.headers.get("user-agent")
    })

    response = await call_next(request)
    return response
```

---

## 📞 On-Call & Incident Response

### PagerDuty Integration

```yaml
Escalation Policy:
  Level 1 (0-15 min):
    - Primary on-call engineer
    - Notification: Phone + SMS + Push

  Level 2 (15-30 min):
    - Secondary on-call engineer
    - Team lead

  Level 3 (30+ min):
    - Engineering manager
    - CTO

Rotation:
  - 1 week rotations
  - Handoff: Monday 9am
  - Compensation: On-call pay + overtime
```

### Runbooks

```markdown
# Runbook: High Error Rate Alert

## Symptoms
- Alert: HighErrorRate (> 5% errors)
- Slack notification in #conductores-alerts

## Investigation
1. Check Grafana dashboard: API Health
2. Check Sentry for recent errors
3. Check CloudWatch Logs for patterns
4. Check integration health (Geotab, Conekta, etc.)

## Common Causes
- External API down (Geotab, Conekta)
- Database connection pool exhausted
- New deployment bug
- DDoS attack

## Resolution Steps
1. If external API down:
   - Enable circuit breaker
   - Return cached data
   - Notify users via status page

2. If database issue:
   - Scale up connection pool
   - Check for slow queries
   - Run VACUUM if needed

3. If deployment bug:
   - Rollback to previous version
   - Check CI/CD logs
   - File incident report

4. If DDoS:
   - Enable rate limiting
   - Activate WAF rules
   - Contact AWS support

## Post-Incident
- Update status page
- Post-mortem within 48 hours
- Create Jira tickets for fixes
```

---

## 📱 Status Page

```yaml
# https://status.conductoresdelmundo.com

Components:
  - API Backend
  - Database (PostgreSQL)
  - Cache (Redis)
  - Geotab Integration
  - Conekta Payments
  - Metamap KYC
  - NEON Disbursements

Incidents:
  - Auto-create from critical alerts
  - Manual updates via Slack bot
  - Subscriber notifications (email/SMS)

Uptime SLA:
  - Target: 99.9% (8.76 hours/year downtime)
  - Current: 99.95%
  - Historical: 30-day, 90-day graphs
```

---

## 🎯 SLOs (Service Level Objectives)

```yaml
API Availability:
  Target: 99.9%
  Measurement: Uptime checks every 1 min
  Error Budget: 43 min/month

API Latency (p95):
  Target: < 300ms
  Measurement: Prometheus metrics
  Error Budget: 5% requests > 300ms

Credit Disbursement Time:
  Target: < 48 hours from approval
  Measurement: Custom metric
  Error Budget: 5% > 48 hours

Payment Success Rate:
  Target: > 95%
  Measurement: Conekta webhook data
  Error Budget: 5% failed payments
```

---

## ✅ Resumen del Manual Quirúrgico CORE

¡Has completado las 7 fases CORE del Manual Quirúrgico!

1. ✅ **DIAGNÓSTICO** - Problema, mercado, propuesta de valor
2. ✅ **ARQUITECTURA** - Stack técnico, integraciones, diseño
3. ✅ **IMPLEMENTACIÓN** - Roadmap, endpoints, código
4. ✅ **INTEGRACIONES** - 8 APIs externas documentadas
5. ✅ **TESTING** - Unit, integration, E2E, CI/CD
6. ✅ **DEPLOYMENT** - AWS, Terraform, blue-green
7. ✅ **MONITORING** - Métricas, logs, alertas, dashboards

**Siguiente:** Archivos IDEAS con expansiones del modelo →
