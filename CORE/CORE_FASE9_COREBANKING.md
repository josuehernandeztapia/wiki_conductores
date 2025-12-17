# FASE 9: COREBANKING - Sistema Bancario Ligero (Odoo + Airtable)

**Versión:** 1.0
**Fecha:** Octubre 2024
**Estado:** ✅ Completo
**Arquitectura:** Odoo (Ledger/Contabilidad) + Airtable (Staging) + Middleware

---

## 🎯 Objetivo

Sistema bancario **ligero y escalable** para Conductores del Mundo que maneja:

- 💰 **Cuentas virtuales** por cliente
- 📊 **Ledger contable** en Odoo
- 💳 **Pagos entrantes** (Conekta, SPEI)
- 🔄 **Dispersiones** (NEON Bank, proveedores)
- 🔐 **Conciliación bancaria** automática
- 📈 **Reporting y auditoría**

**Sin core bancario tradicional** → Uso de Odoo + Airtable + APIs.

> La configuración completa de productos, journals, cuentas y parámetros de Odoo se documenta en `ANEXO_ODOO_SETUP.md`.

---

## 🏗️ ARQUITECTURA

```
┌─────────────────────────────────────────────────────────────┐
│              CORE BANCARIO LIGERO - ARQUITECTURA            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Cliente/Portal] → [Middleware] → [Airtable Staging]      │
│                           ↓              ↓                  │
│                      [Odoo ERP]    [Validaciones]          │
│                    (Ledger/Contabilidad)                    │
│                           ↓                                 │
│                  [Conciliación Bancaria]                    │
│                           ↓                                 │
│                  [Reportes & Estados]                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 14 PASOS DEL FLUJO OPERATIVO

### **Paso 1: Onboarding Cliente**

**Actor:** Cliente
**Sistema:** PWA + Backend

**Flujo:**
1. Cliente completa registro en PWA
2. KYC básico con Metamap (INE + selfie)
3. Validación RFC/CURP
4. Creación de registro en `customers` (NEON)

**Output:** `customer_id` generado

---

### **Paso 2: Alta Cuenta Virtual**

**Actor:** Middleware (Make/API)
**Sistema:** Odoo + NEON

**API Endpoint:**
```
POST /v1/core/accounts
{
  "customer_id": "uuid",
  "account_type": "virtual",
  "currency": "MXN"
}
```

**Acciones:**
1. Crear cuenta virtual en módulo Odoo personalizado
2. Asignar número de cuenta único (ACT-{customer_id})
3. Generar CLABE virtual (si aplica con banco partner)
4. Registrar en tabla `virtual_accounts` (NEON)

**Output:** `account_number`, `clabe_virtual`

---

### **Paso 3: Generar Referencia de Pago**

**Actor:** Cliente solicita referencia
**Sistema:** Conekta API

**Flujo:**
1. Cliente desde PWA solicita "Hacer pago"
2. Backend genera referencia SPEI única:
   ```python
   POST https://api.conekta.io/oxxo_cash/orders
   {
     "amount": 5000,  # MXN cents
     "currency": "MXN",
     "customer_info": {...},
     "line_items": [...]
   }
   ```
3. Conekta retorna:
   - Referencia SPEI (18 dígitos)
   - Referencia OXXO (14 dígitos)
   - QR code
   - Fecha expiración (72 horas)

**Output:** Referencias enviadas a cliente via WhatsApp/Email

---

### **Paso 4: Pago Entrante (Gateway)**

**Actor:** Cliente paga en OXXO/banco
**Sistema:** Conekta procesa pago

**Webhook recibido:**
```json
{
  "event": "order.paid",
  "data": {
    "object": {
      "id": "ord_2tYj8z...",
      "amount": 5000,
      "currency": "MXN",
      "payment_status": "paid",
      "charges": [{
        "id": "chr_...",
        "amount": 5000,
        "payment_method": {
          "type": "oxxo_cash",
          "reference": "98765432101234"
        }
      }]
    }
  }
}
```

---

### **Paso 5: Webhook → Staging (Airtable)**

**Actor:** Middleware (Make.com)
**Sistema:** Airtable

**Flujo:**
1. Webhook de Conekta recibido en Make.com
2. Make.com parsea el payload
3. Crea registro en Airtable tabla `transactions_staging`:

| Campo | Valor |
|-------|-------|
| transaction_id | chr_abc123 |
| customer_id | uuid |
| amount | 50.00 MXN |
| payment_method | oxxo_cash |
| reference | 98765432101234 |
| status | pending_validation |
| timestamp | 2025-01-15 10:30:00 |

**Status inicial:** `pending_validation`

---

### **Paso 6: Validación Antifraude**

**Actor:** Script automatizado (Make/Zapier)
**Sistema:** Reglas de negocio

**Validaciones:**
1. **Duplicados:** Verificar si `reference` ya existe en últimas 24h
2. **Monto:** Validar que monto sea >= min y <= max permitido
3. **Cliente:** Verificar que `customer_id` esté activo
4. **Lista negra:** Verificar que referencia no esté en blacklist
5. **Velocidad:** Máximo 3 pagos/día por cliente

**Código (pseudocódigo):**
```python
def validate_transaction(tx):
    # 1. Duplicado
    if Transaction.exists(reference=tx.reference, created_at__gte=now()-24h):
        return REJECT("DUPLICATE")

    # 2. Monto
    if tx.amount < 100 or tx.amount > 50000:
        return REJECT("AMOUNT_OUT_OF_RANGE")

    # 3. Cliente activo
    customer = Customer.get(tx.customer_id)
    if customer.status != 'active':
        return REJECT("CUSTOMER_INACTIVE")

    # 4. Blacklist
    if tx.reference in BLACKLIST:
        return REJECT("BLACKLISTED")

    # 5. Velocidad
    count_today = Transaction.count(customer_id=tx.customer_id, date=today)
    if count_today >= 3:
        return REJECT("VELOCITY_LIMIT")

    return APPROVE()
```

**Output:** Status actualizado en Airtable:
- `approved` → Continuar a Paso 7
- `rejected` → Notificar cliente y detener

---

### **Paso 7: Asiento en Odoo (Ledger)**

**Actor:** Middleware → Odoo API
**Sistema:** Odoo Contabilidad

**API Call:**
```python
POST /api/v1/account.move
{
  "journal_id": 1,  # Diario "Pagos Clientes"
  "date": "2025-01-15",
  "ref": "PAGO-chr_abc123",
  "line_ids": [
    {
      "account_id": 101,  # Banco
      "debit": 50.00,
      "credit": 0
    },
    {
      "account_id": 405,  # Ingreso por financiamiento
      "debit": 0,
      "credit": 50.00
    }
  ]
}
```

**Cuentas Odoo:**
- **101** - Banco NEON (Activo)
- **102** - Conekta por cobrar (Activo)
- **405** - Ingreso por pagos clientes (Ingreso)
- **201** - Cuentas por pagar proveedores (Pasivo)

**Output:** Asiento contable registrado, `move_id` generado

---

### **Paso 8: Conciliación Bancaria**

**Actor:** Proceso nocturno (cron job)
**Sistema:** Odoo Conciliación Bancaria

**Flujo:**
1. **Obtener extracto bancario:**
   ```python
   GET /neon_bank/api/statements?date=2025-01-15
   ```

2. **Comparar con ledger Odoo:**
   - Extracto bancario: $50.00 entrada a las 10:30
   - Ledger Odoo: move_id #1234, $50.00 a las 10:30
   - **Match:** ✅ Conciliar automáticamente

3. **Si no match:**
   - Crear alerta en Airtable
   - Asignar a revisor contable

**Query SQL (NEON):**
```sql
SELECT
  t.id,
  t.amount,
  t.reference,
  t.created_at,
  o.move_id AS odoo_move_id
FROM transactions t
LEFT JOIN odoo_moves o ON t.reference = o.ref
WHERE t.created_at::date = '2025-01-15'
  AND o.move_id IS NULL;  -- Sin match
```

---

### **Paso 9: Notificación y Recibo**

**Actor:** Sistema de notificaciones
**Sistema:** Twilio (WhatsApp) + SendGrid (Email)

**Flujo:**
1. Pago aprobado y conciliado → Trigger notificación
2. Generar recibo PDF:
   ```python
   from reportlab.lib.pagesizes import letter
   from reportlab.pdfgen import canvas

   def generate_receipt(transaction):
       pdf = canvas.Canvas(f"recibo_{transaction.id}.pdf", pagesize=letter)
       pdf.drawString(100, 750, "CONDUCTORES DEL MUNDO")
       pdf.drawString(100, 730, f"Recibo de Pago #{transaction.id}")
       pdf.drawString(100, 710, f"Monto: ${transaction.amount} MXN")
       pdf.drawString(100, 690, f"Fecha: {transaction.timestamp}")
       pdf.drawString(100, 670, f"Referencia: {transaction.reference}")
       pdf.save()
   ```

3. Enviar via WhatsApp:
   ```python
   twilio_client.messages.create(
       from_='whatsapp:+14155238886',
       body='✅ Pago recibido: $50.00 MXN. Gracias por tu pago!',
       to=f'whatsapp:+52{customer.phone}',
       media_url=[receipt_pdf_url]
   )
   ```

---

### **Paso 10: Dispersión/Egreso**

**Actor:** Proceso de pagos (manual o automático)
**Sistema:** NEON Bank API

**Caso de uso:** Pagar a proveedor (ej. refacciones)

**API Call:**
```python
POST /neon_bank/api/spei/transfer
{
  "amount": 15000.00,
  "currency": "MXN",
  "recipient": {
    "name": "PROVEEDOR HIGER SA",
    "clabe": "012345678901234567",
    "rfc": "PHI850101ABC"
  },
  "concept": "PAGO REFACCIONES ORD-12345",
  "reference": "DISP-001"
}
```

**Validaciones previas:**
1. Saldo suficiente en cuenta
2. Límite diario no excedido
3. Aprobación dual (2FA)

**Asiento Odoo (egreso):**
```python
{
  "journal_id": 2,  # Diario Egresos
  "line_ids": [
    {"account_id": 201, "debit": 15000, "credit": 0},  # Proveedores
    {"account_id": 101, "debit": 0, "credit": 15000}   # Banco
  ]
}
```

---

### **Paso 11: Estados de Cuenta**

**Actor:** Cliente solicita estado de cuenta
**Sistema:** Odoo Reports + PDF

**Generación:**
```python
def generate_statement(customer_id, month):
    # Obtener transacciones del mes
    transactions = Transaction.filter(
        customer_id=customer_id,
        created_at__month=month
    ).order_by('created_at')

    # Balance inicial y final
    balance_start = Account.get(customer_id).balance_at(start_of_month)
    balance_end = balance_start

    # Generar PDF
    pdf = generate_pdf_template('statement.html', {
        'customer': customer,
        'month': month,
        'balance_start': balance_start,
        'transactions': transactions,
        'balance_end': balance_end
    })

    return pdf
```

**Contenido:**
- Balance inicial
- Transacciones (ingresos/egresos)
- Cargos/comisiones
- Balance final

---

### **Paso 12: Reportes & BI**

**Actor:** Equipo financiero
**Sistema:** Airtable Dashboards + Metabase

**Dashboards clave:**

1. **Ingresos diarios:**
   ```sql
   SELECT
     DATE(created_at) AS date,
     COUNT(*) AS transactions,
     SUM(amount) AS total_mxn
   FROM transactions
   WHERE status = 'approved'
   GROUP BY DATE(created_at)
   ORDER BY date DESC
   LIMIT 30;
   ```

2. **Cartera vencida:**
   ```sql
   SELECT
     c.contract_number,
     cu.first_name || ' ' || cu.last_name AS customer,
     c.monthly_payment,
     COUNT(CASE WHEN t.status = 'late' THEN 1 END) AS late_payments,
     MAX(t.due_date) AS last_due_date
   FROM contracts c
   JOIN customers cu ON c.customer_id = cu.id
   LEFT JOIN transactions t ON c.id = t.contract_id
   WHERE c.status = 'active'
   GROUP BY c.id, cu.id
   HAVING COUNT(CASE WHEN t.status = 'late' THEN 1 END) > 0
   ORDER BY late_payments DESC;
   ```

3. **Dispersiones pendientes:**
   ```sql
   SELECT
     provider_name,
     COUNT(*) AS pending_payments,
     SUM(amount) AS total_pending
   FROM disbursements
   WHERE status = 'pending'
   GROUP BY provider_name;
   ```

---

### **Paso 13: Excepciones / PLD**

**Actor:** Compliance Officer
**Sistema:** Alertas automáticas

**Reglas PLD (Prevención Lavado Dinero):**

1. **Operación inusual:** Pago > $10,000 MXN en efectivo
2. **Operación relevante:** Acumulado mensual > $50,000 MXN
3. **Operación sospechosa:** Patrones anómalos

**Script de detección:**
```python
def detect_pld_alerts():
    # 1. Operaciones inusuales (>$10K cash)
    unusual = Transaction.filter(
        amount__gt=10000,
        payment_method='cash',
        created_at__gte=now()-timedelta(days=1)
    )

    # 2. Operaciones relevantes (acumulado mensual >$50K)
    relevant = Customer.annotate(
        monthly_total=Sum('transactions__amount',
                          filter=Q(transactions__created_at__month=current_month))
    ).filter(monthly_total__gt=50000)

    # 3. Patrones sospechosos (múltiples pagos inmediatos)
    suspicious = Transaction.raw("""
        SELECT customer_id, COUNT(*) as count
        FROM transactions
        WHERE created_at >= NOW() - INTERVAL '1 hour'
        GROUP BY customer_id
        HAVING COUNT(*) >= 5
    """)

    # Crear alertas en Airtable
    for tx in unusual:
        create_alert('UNUSUAL_OPERATION', tx)

    for customer in relevant:
        create_alert('RELEVANT_OPERATION', customer)

    for pattern in suspicious:
        create_alert('SUSPICIOUS_PATTERN', pattern)
```

**Reporte mensual CNBV:**
- Exportar alertas generadas
- Adjuntar evidencia
- Enviar via plataforma CNBV

---

### **Paso 14: Hardening & Retención**

**Actor:** DevOps / SysAdmin
**Sistema:** AWS S3 / MinIO

**Políticas de retención:**

| Tipo de dato | Retención | Storage |
|--------------|-----------|---------|
| Transacciones | 7 años | NEON DB + S3 |
| Documentos KYC | 5 años | S3 encrypted |
| Logs de auditoría | 2 años | CloudWatch Logs |
| Recibos PDF | 5 años | S3 |
| Grabaciones llamadas | 6 meses | S3 Glacier |

**Script de backup:**
```bash
#!/bin/bash
# backup_daily.sh

# 1. Backup DB
pg_dump $NEON_DATABASE_URL | gzip > backup_$(date +%Y%m%d).sql.gz

# 2. Upload a S3
aws s3 cp backup_$(date +%Y%m%d).sql.gz s3://conductores-backups/daily/

# 3. Retención (eliminar backups >30 días)
aws s3 ls s3://conductores-backups/daily/ \
  | awk '{print $4}' \
  | while read file; do
      date_str=$(echo $file | grep -oP '\d{8}')
      file_date=$(date -d "$date_str" +%s)
      cutoff_date=$(date -d "30 days ago" +%s)
      if [ $file_date -lt $cutoff_date ]; then
          aws s3 rm s3://conductores-backups/daily/$file
      fi
  done
```

---

## 🛠️ MÓDULO ODOO PERSONALIZADO

### Instalación

```bash
# 1. Clonar módulo
cd /opt/odoo/custom/addons
git clone https://github.com/conductores/odoo_corebanking.git

# 2. Activar en Odoo
# Apps > Actualizar lista de aplicaciones
# Buscar "Core Banking Conductores" > Instalar
```

### Estructura del módulo

```
odoo_corebanking/
├── __manifest__.py
├── models/
│   ├── virtual_account.py
│   ├── transaction.py
│   └── reconciliation.py
├── views/
│   ├── virtual_account_views.xml
│   └── transaction_views.xml
├── security/
│   └── ir.model.access.csv
└── data/
    └── accounts_data.xml
```

### Modelo: `virtual_account.py`

```python
from odoo import models, fields, api

class VirtualAccount(models.Model):
    _name = 'corebanking.virtual_account'
    _description = 'Cuenta Virtual Cliente'

    name = fields.Char(string='Número de Cuenta', required=True)
    customer_id = fields.Char(string='Customer ID (NEON)', required=True)
    balance = fields.Float(string='Saldo', compute='_compute_balance')
    currency_id = fields.Many2one('res.currency', default=lambda self: self.env.ref('base.MXN'))
    status = fields.Selection([
        ('active', 'Activa'),
        ('blocked', 'Bloqueada'),
        ('closed', 'Cerrada')
    ], default='active')

    transaction_ids = fields.One2many('corebanking.transaction', 'account_id', string='Transacciones')

    @api.depends('transaction_ids.amount', 'transaction_ids.type')
    def _compute_balance(self):
        for account in self:
            credits = sum(account.transaction_ids.filtered(lambda t: t.type == 'credit').mapped('amount'))
            debits = sum(account.transaction_ids.filtered(lambda t: t.type == 'debit').mapped('amount'))
            account.balance = credits - debits
```

---

## 📊 KPIs Y MÉTRICAS

| Métrica | Target | Actual | Fórmula |
|---------|--------|--------|---------|
| **Tasa conciliación** | > 95% | - | (Transacciones conciliadas / Total) × 100 |
| **Tiempo conciliación** | < 24h | - | AVG(tiempo desde pago hasta conciliación) |
| **Excepciones PLD** | < 1% | - | (Alertas PLD / Total transacciones) × 100 |
| **Uptime sistema** | > 99.5% | - | (Tiempo activo / Tiempo total) × 100 |
| **Tiempo dispersión** | < 48h | - | AVG(tiempo desde solicitud hasta SPEI enviado) |

---

## 🔐 SEGURIDAD

### Controles implementados:

1. **Autenticación 2FA** para dispersiones > $10,000
2. **Encriptación** en tránsito (TLS 1.3) y reposo (AES-256)
3. **Logs de auditoría** inmutables (append-only)
4. **Separación de ambientes** (dev, staging, production)
5. **Whitelisting IP** para APIs sensibles
6. **Rate limiting** (100 req/min por cliente)

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

- [ ] Configurar módulo Odoo Corebanking
- [ ] Crear cuentas contables en catálogo
- [ ] Integrar Conekta webhooks
- [ ] Configurar NEON Bank API
- [ ] Implementar validaciones antifraude
- [ ] Configurar conciliación automática
- [ ] Configurar notificaciones (Twilio + SendGrid)
- [ ] Implementar dashboards en Metabase
- [ ] Configurar alertas PLD
- [ ] Implementar backups automáticos
- [ ] Documentar runbooks operativos
- [ ] Capacitar equipo financiero

---

## 📚 REFERENCIAS

- Odoo Accounting: https://www.odoo.com/documentation/16.0/applications/finance/accounting.html
- Conekta API: https://developers.conekta.com/
- NEON Bank API: https://docs.neon.tech/
- Norma PLD México: https://www.cnbv.gob.mx/

---

**Última actualización:** Octubre 2024
**Responsable:** Equipo Finanzas + Tech
