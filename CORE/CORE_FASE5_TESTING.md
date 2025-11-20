# CORE FASE 5: ESTRATEGIA DE TESTING

## 🎯 Objetivo
Definir estrategia completa de testing (unit, integration, E2E) con coverage targets y CI/CD automation.

---

## 🧪 Pirámide de Testing

```
                    ▲
                   /E\
                  /2E \         5% - E2E Tests
                 /─────\        (Cypress/Playwright)
                /       \
               / Integr. \      15% - Integration Tests
              /───────────\     (API endpoints + DB)
             /             \
            /  Unit Tests   \   80% - Unit Tests
           /─────────────────\  (Services + Utils)
          /_____________________\
```

---

## ✅ Unit Tests (80% cobertura)

### Servicios de Negocio

#### 1. Cotizador Service
```python
# tests/unit/test_cotizador.py
import pytest
from decimal import Decimal
from services.cotizador import CotizadorService

class TestCotizadorService:
    def setup_method(self):
        self.cotizador = CotizadorService()

    def test_calculate_quote_basic(self):
        """Test cotización básica con valores válidos"""
        result = self.cotizador.calculate_quote(
            precio_vehiculo=Decimal("300000"),
            enganche=Decimal("50000"),
            plazo_meses=36
        )

        assert result["monto_financiar"] == Decimal("250000")
        assert len(result["scenarios"]) == 4
        assert result["scenarios"][0]["escenario"] == "conservative"

    def test_pmt_formula_accuracy(self):
        """Test precisión fórmula PMT vs Excel"""
        pago = self.cotizador._calculate_pmt(
            monto=Decimal("250000"),
            tasa_anual=Decimal("0.14"),
            plazo_meses=36
        )

        # Comparar con Excel PMT
        assert abs(pago - Decimal("8567.11")) < Decimal("0.01")

    def test_payment_schedule_sum(self):
        """Test suma de pagos = monto + intereses"""
        schedule = self.cotizador.generate_payment_schedule(
            monto=Decimal("250000"),
            tasa_anual=Decimal("0.14"),
            plazo_meses=36
        )

        total_pagado = sum(p["monto"] for p in schedule)
        total_esperado = Decimal("308556")  # Monto + intereses

        assert abs(total_pagado - total_esperado) < Decimal("1.00")

    def test_invalid_enganche_percentage(self):
        """Test rechazo enganche < 10%"""
        with pytest.raises(ValueError, match="Enganche mínimo 10%"):
            self.cotizador.calculate_quote(
                precio_vehiculo=Decimal("300000"),
                enganche=Decimal("20000"),  # 6.7% < 10%
                plazo_meses=36
            )

    def test_invalid_plazo(self):
        """Test rechazo plazo fuera de rango"""
        with pytest.raises(ValueError, match="Plazo debe estar entre 12 y 60 meses"):
            self.cotizador.calculate_quote(
                precio_vehiculo=Decimal("300000"),
                enganche=Decimal("50000"),
                plazo_meses=72
            )
```

#### 2. Motor HASE Service
```python
# tests/unit/test_motor_hase.py
import pytest
import pandas as pd
from services.motor_hase import MotorHASE

class TestMotorHASE:
    def setup_method(self):
        self.motor = MotorHASE()

    def test_extract_telemetry_features(self):
        """Test extracción features de telemetría"""
        telemetria_df = pd.DataFrame({
            'fecha': pd.date_range('2024-01-01', periods=30),
            'horas_activas': [8.5] * 30,
            'km_recorridos': [120.0] * 30,
            'driver_score': [85] * 30
        })

        features = self.motor._extract_telemetry_features(telemetria_df)

        assert features['dias_trabajados_30d'] == 30
        assert features['horas_activas_avg_30d'] == 8.5
        assert features['driver_score_avg'] == 85.0

    def test_sinosure_tier_assignment(self):
        """Test asignación tier SINOSURE según score"""
        assert self.motor._assign_sinosure_tier(95) == "AAA"
        assert self.motor._assign_sinosure_tier(85) == "AA"
        assert self.motor._assign_sinosure_tier(70) == "A"
        assert self.motor._assign_sinosure_tier(55) == "B"

    def test_rule_based_scoring(self):
        """Test scoring basado en reglas (fallback sin ML)"""
        features = {
            'dias_trabajados_30d': 28,
            'horas_activas_avg_30d': 9.0,
            'driver_score_avg': 85,
            'ingresos_mensuales': 25000,
            'debt_to_income': 0.3,
        }

        score = self.motor._rule_based_score(features)

        assert 70 <= score <= 90

    @pytest.mark.asyncio
    async def test_score_conductor_complete(self):
        """Test flujo completo de scoring"""
        telemetria_df = pd.DataFrame({...})
        financial_data = {...}
        social_data = {...}

        result = await self.motor.score_conductor(
            conductor_id="uuid-123",
            telemetria_data=telemetria_df,
            financial_data=financial_data,
            social_data=social_data
        )

        assert 0 <= result['score_hase'] <= 100
        assert result['sinosure_tier'] in ["AAA", "AA", "A", "B"]
        assert 'recommendation' in result
```

#### 3. Auth Service
```python
# tests/unit/test_auth.py
import pytest
from services.auth import AuthService

class TestAuthService:
    def setup_method(self):
        self.auth = AuthService()

    def test_password_hashing(self):
        """Test password hash bcrypt"""
        password = "securepassword123"
        hashed = self.auth.hash_password(password)

        assert hashed != password
        assert hashed.startswith("$2b$")
        assert len(hashed) == 60

    def test_password_verification_correct(self):
        """Test verificación password correcta"""
        password = "securepassword123"
        hashed = self.auth.hash_password(password)

        assert self.auth.verify_password(password, hashed) is True

    def test_password_verification_incorrect(self):
        """Test verificación password incorrecta"""
        password = "securepassword123"
        hashed = self.auth.hash_password(password)

        assert self.auth.verify_password("wrongpassword", hashed) is False

    def test_create_access_token(self):
        """Test creación JWT token"""
        conductor_id = "123e4567-e89b-12d3-a456-426614174000"
        token = self.auth.create_access_token(conductor_id)

        assert isinstance(token, str)
        assert token.count(".") == 2  # JWT format

    def test_decode_valid_token(self):
        """Test decodificación token válido"""
        conductor_id = "123e4567-e89b-12d3-a456-426614174000"
        token = self.auth.create_access_token(conductor_id)

        decoded_id = self.auth.decode_token(token)

        assert decoded_id == conductor_id

    def test_decode_invalid_token(self):
        """Test decodificación token inválido"""
        invalid_token = "invalid.token.here"

        decoded_id = self.auth.decode_token(invalid_token)

        assert decoded_id is None

    def test_decode_expired_token(self):
        """Test decodificación token expirado"""
        # Mock tiempo futuro
        from unittest.mock import patch
        import time

        conductor_id = "123e4567-e89b-12d3-a456-426614174000"
        token = self.auth.create_access_token(conductor_id)

        # Simular 2 horas después (token expira en 1 hora)
        with patch('time.time', return_value=time.time() + 7200):
            decoded_id = self.auth.decode_token(token)
            assert decoded_id is None
```

### Coverage Target
```yaml
Unit Tests Coverage: 80%+

Prioridad Alta (90%+):
  - services/ (business logic)
  - utils/security.py
  - utils/validators.py

Prioridad Media (70%+):
  - integrations/ (mocked)
  - api/routes/ (endpoints)

Prioridad Baja (50%+):
  - main.py
  - config/settings.py
```

---

## 🔗 Integration Tests (15% cobertura)

### API Endpoints + Database

```python
# tests/integration/test_api.py
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from main import app
from database.session import get_session

@pytest.fixture
async def test_db():
    """Fixture: test database en memoria"""
    from sqlalchemy.ext.asyncio import create_async_engine
    from database.base import Base

    engine = create_async_engine("sqlite+aiosqlite:///:memory:")

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    yield engine

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

@pytest.fixture
async def client(test_db):
    """Fixture: HTTP test client"""
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

@pytest.mark.asyncio
async def test_root_endpoint(client):
    """Test endpoint raíz"""
    response = await client.get("/")

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "operational"
    assert data["version"] == "1.0.0"

@pytest.mark.asyncio
async def test_health_endpoint(client):
    """Test health check"""
    response = await client.get("/health")

    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "database" in data
    assert "redis" in data

@pytest.mark.asyncio
async def test_register_conductor(client):
    """Test registro de conductor"""
    response = await client.post("/api/v1/auth/register", json={
        "nombre_completo": "Juan Pérez",
        "email": "juan@example.com",
        "telefono": "+5215512345678",
        "password": "securepass123"
    })

    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "juan@example.com"
    assert "id" in data
    assert "password" not in data

@pytest.mark.asyncio
async def test_login_conductor(client):
    """Test login con credenciales correctas"""
    # 1. Registro
    await client.post("/api/v1/auth/register", json={
        "nombre_completo": "Juan Pérez",
        "email": "juan@example.com",
        "telefono": "+5215512345678",
        "password": "securepass123"
    })

    # 2. Login
    response = await client.post("/api/v1/auth/login", json={
        "email": "juan@example.com",
        "password": "securepass123"
    })

    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"

@pytest.mark.asyncio
async def test_cotizador_endpoint(client):
    """Test cotizador sin autenticación"""
    response = await client.post("/api/v1/cotizador/quote", json={
        "precio_vehiculo": 300000,
        "enganche": 50000,
        "plazo_meses": 36
    })

    assert response.status_code == 200
    data = response.json()
    assert data["monto_financiar"] == 250000
    assert len(data["scenarios"]) == 4
    assert data["scenarios"][0]["escenario"] == "conservative"

@pytest.mark.asyncio
async def test_submit_application_authenticated(client):
    """Test submit application con JWT"""
    # 1. Registro + login
    await client.post("/api/v1/auth/register", json={...})
    login_response = await client.post("/api/v1/auth/login", json={...})
    token = login_response.json()["access_token"]

    # 2. Submit application
    response = await client.post(
        "/api/v1/applications/submit",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "monto_solicitado": 250000,
            "plazo_meses": 36,
            "vehiculo_tipo": "sedan",
            "ingresos_mensuales": 25000
        }
    )

    assert response.status_code == 201
    data = response.json()
    assert data["status"] == "pending"
    assert "id" in data

@pytest.mark.asyncio
async def test_unauthorized_access(client):
    """Test acceso sin token"""
    response = await client.get("/api/v1/conductores/me")

    assert response.status_code == 401
```

---

## 🌐 E2E Tests (5% cobertura)

### Flujos Críticos con Cypress

```javascript
// cypress/e2e/cotizador_flow.cy.js
describe('Flujo Cotizador Completo', () => {
  it('Cotización → Registro → Solicitud → Pago', () => {
    // 1. Cotización (público)
    cy.visit('/cotizador')
    cy.get('#precio-vehiculo').type('300000')
    cy.get('#enganche').type('50000')
    cy.get('#plazo').select('36 meses')
    cy.get('#btn-cotizar').click()

    cy.contains('Escenario Conservative')
    cy.contains('$8,567/mes')

    // 2. Click "Solicitar crédito"
    cy.get('#btn-solicitar').click()

    // 3. Registro
    cy.url().should('include', '/registro')
    cy.get('#nombre').type('Juan Pérez')
    cy.get('#email').type('juan@example.com')
    cy.get('#telefono').type('5512345678')
    cy.get('#password').type('SecurePass123!')
    cy.get('#btn-registrar').click()

    // 4. Verificar redirección a dashboard
    cy.url().should('include', '/dashboard')
    cy.contains('Bienvenido, Juan Pérez')

    // 5. Completar solicitud
    cy.visit('/solicitud')
    cy.get('#ingresos').type('25000')
    cy.get('#vehiculo-tipo').select('Sedan')
    cy.get('#btn-submit').click()

    // 6. Confirmar solicitud creada
    cy.contains('Solicitud enviada')
    cy.contains('En revisión')
  })
})

// cypress/e2e/payment_flow.cy.js
describe('Flujo de Pago', () => {
  beforeEach(() => {
    // Setup: usuario con crédito aprobado
    cy.loginAs('conductor_con_credito@test.com')
  })

  it('Pagar mensualidad con tarjeta', () => {
    cy.visit('/mis-creditos')
    cy.get('.credito-activo').first().click()

    cy.contains('Próximo pago')
    cy.get('#btn-pagar').click()

    // Formulario Conekta
    cy.get('#card-number').type('4242424242424242')
    cy.get('#exp-month').type('12')
    cy.get('#exp-year').type('25')
    cy.get('#cvv').type('123')
    cy.get('#btn-procesar-pago').click()

    // Confirmar éxito
    cy.contains('Pago exitoso', {timeout: 10000})
    cy.contains('Recibo generado')
  })
})
```

---

## 🤖 CI/CD Testing Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Test Suite

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  unit-tests:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: Setup Python 3.11
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install pytest pytest-cov pytest-asyncio

      - name: Run unit tests
        run: |
          pytest tests/unit/ \
            --cov=src \
            --cov-report=xml \
            --cov-report=html \
            --cov-fail-under=80

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml

  integration-tests:
    runs-on: ubuntu-latest
    needs: unit-tests

    steps:
      - uses: actions/checkout@v3

      - name: Setup Python 3.11
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Run integration tests
        run: pytest tests/integration/ -v

  e2e-tests:
    runs-on: ubuntu-latest
    needs: integration-tests

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install Cypress
        run: npm install cypress

      - name: Run E2E tests
        run: npx cypress run
        env:
          CYPRESS_BASE_URL: http://localhost:4200
```

---

## 📊 Métricas de Calidad

```yaml
Coverage Targets:
  Overall: 80%+
  Services: 90%+
  Routes: 70%+
  Utils: 85%+

Performance Tests:
  - API response time < 200ms (p95)
  - Database queries < 100ms
  - Load test: 1000 req/s sin errores

Security Tests:
  - OWASP ZAP scan
  - Dependency vulnerability scan (Snyk)
  - SQL injection tests
  - XSS tests

Code Quality:
  - mypy strict mode (0 errors)
  - pylint score > 9.0
  - black formatting
  - isort imports
```

---

## 🚀 Siguiente Fase

**→ CORE_FASE6_DEPLOYMENT.md**
- Estrategia de deployment
- Infraestructura AWS
- CI/CD pipeline completo
- Rollback strategy
