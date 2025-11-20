# CORE FASE 6: DEPLOYMENT & DEVOPS

## 🎯 Objetivo
Estrategia de deployment en AWS con CI/CD automation, infraestructura como código, y rollback strategy.

---

## ☁️ Infraestructura AWS

### Arquitectura de Producción

```
┌──────────────────────────────────────────────────────────┐
│                     INTERNET                              │
└──────────────────┬───────────────────────────────────────┘
                   │
                   ▼
         ┌─────────────────┐
         │  Route 53 (DNS) │
         └─────────────────┘
                   │
                   ▼
         ┌─────────────────┐
         │   CloudFront    │ ← CDN (frontend assets)
         │   (CDN)         │
         └─────────────────┘
                   │
         ┌─────────┴──────────┐
         │                    │
         ▼                    ▼
┌──────────────┐    ┌──────────────────┐
│   S3 Bucket  │    │       ALB        │ ← Load Balancer
│  (Frontend)  │    │ (Application LB) │
└──────────────┘    └──────────────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
                    ▼                 ▼
           ┌─────────────┐   ┌─────────────┐
           │   ECS/Fargate│   │ ECS/Fargate │ ← Auto-scaling
           │   (Backend 1)│   │ (Backend 2) │   2-10 tasks
           └─────────────┘   └─────────────┘
                    │                 │
         ┌──────────┴─────────────────┴──────────┐
         │                                        │
         ▼                                        ▼
┌──────────────────┐                   ┌──────────────────┐
│   RDS PostgreSQL │                   │ ElastiCache Redis│
│   Multi-AZ       │                   │  Cluster         │
│   db.t3.large    │                   │  cache.t3.micro  │
└──────────────────┘                   └──────────────────┘
         │
         ▼
┌──────────────────┐
│   S3 Backups     │ ← Automated daily backups
└──────────────────┘
```

### Recursos AWS

```yaml
# terraform/main.tf
provider "aws" {
  region = "us-east-1"
}

# VPC & Networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "conductores-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "conductores-public-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "conductores-private-${count.index}"
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier           = "conductores-db"
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = "db.t3.large"
  allocated_storage    = 100
  storage_type         = "gp3"

  multi_az             = true
  db_subnet_group_name = aws_db_subnet_group.main.name

  username             = "conductores_admin"
  password             = var.db_password  # From AWS Secrets Manager

  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name = "conductores-postgres"
  }
}

# ElastiCache Redis
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "conductores-redis"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.main.name

  tags = {
    Name = "conductores-redis"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "conductores-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "conductores-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"  # 1 vCPU
  memory                   = "2048"  # 2 GB
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name  = "backend"
    image = "${aws_ecr_repository.backend.repository_url}:latest"

    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]

    environment = [
      {name = "DATABASE_URL", value = "postgresql+asyncpg://..."},
      {name = "REDIS_URL", value = "redis://..."},
    ]

    secrets = [
      {name = "SECRET_KEY", valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:secret_key::"},
      {name = "GEOTAB_PASSWORD", valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:geotab_password::"},
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/conductores-backend"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])
}

# ECS Service with Auto-scaling
resource "aws_ecs_service" "backend" {
  name            = "conductores-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.backend.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.backend]
}

# Auto-scaling
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

# S3 Buckets
resource "aws_s3_bucket" "frontend" {
  bucket = "conductores-frontend-prod"

  tags = {
    Name = "conductores-frontend"
  }
}

resource "aws_s3_bucket" "documents" {
  bucket = "conductores-documents-prod"

  tags = {
    Name = "conductores-documents"
  }
}

resource "aws_s3_bucket" "backups" {
  bucket = "conductores-backups-prod"

  lifecycle_rule {
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}
```

---

## 🚀 CI/CD Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: conductores-backend
  ECS_CLUSTER: conductores-cluster
  ECS_SERVICE: conductores-backend

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Run tests
        run: |
          pytest tests/ \
            --cov=src \
            --cov-fail-under=80

      - name: Run linters
        run: |
          black --check src/
          mypy src/
          pylint src/

  build:
    needs: test
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.build-image.outputs.image }}

    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build, tag, and push image to ECR
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
          echo "image=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_OUTPUT

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: production

    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Update ECS service
        run: |
          aws ecs update-service \
            --cluster ${{ env.ECS_CLUSTER }} \
            --service ${{ env.ECS_SERVICE }} \
            --force-new-deployment \
            --region ${{ env.AWS_REGION }}

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster ${{ env.ECS_CLUSTER }} \
            --services ${{ env.ECS_SERVICE }} \
            --region ${{ env.AWS_REGION }}

      - name: Health check
        run: |
          HEALTH_URL="https://api.conductoresdelmundo.com/health"
          for i in {1..10}; do
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_URL)
            if [ $STATUS -eq 200 ]; then
              echo "✅ Health check passed"
              exit 0
            fi
            echo "⏳ Waiting for health check... ($i/10)"
            sleep 30
          done
          echo "❌ Health check failed"
          exit 1

  deploy-frontend:
    needs: test
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Build Angular app
        run: |
          cd frontend
          npm ci
          npm run build -- --configuration production

      - name: Deploy to S3
        run: |
          aws s3 sync frontend/dist/conductores-pwa s3://conductores-frontend-prod --delete

      - name: Invalidate CloudFront
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/*"

  notify:
    needs: [deploy, deploy-frontend]
    runs-on: ubuntu-latest
    if: always()

    steps:
      - name: Notify Slack
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: |
            Deploy to production: ${{ job.status }}
            Commit: ${{ github.sha }}
            Author: ${{ github.actor }}
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 🔄 Deployment Strategies

### Blue-Green Deployment

```yaml
# Mantener 2 task definitions (blue/green)
# Cambiar tráfico ALB gradualmente

Blue (Actual):
  - Task definition: conductores-backend:42
  - Containers: 2
  - ALB Target Group: blue-tg
  - Traffic: 100%

Deploy Green:
  1. Create new task definition: conductores-backend:43
  2. Deploy to green-tg (0% traffic)
  3. Health checks pass
  4. Shift 10% traffic to green-tg
  5. Monitor 5 min
  6. Shift 50% traffic
  7. Monitor 5 min
  8. Shift 100% traffic
  9. Decommission blue

Rollback (si falla):
  - Shift 100% traffic back to blue
  - Total time: < 2 minutes
```

### Canary Deployment

```yaml
# Para features de alto riesgo
# Desplegar a un % pequeño de usuarios

Canary Strategy:
  1. Deploy canary (5% users)
  2. Monitor metrics 15 min:
     - Error rate < 1%
     - Latency p95 < 300ms
     - 0 crashes
  3. If pass: Increase to 25%
  4. Monitor 15 min
  5. If pass: Increase to 50%
  6. Monitor 15 min
  7. If pass: Full deployment (100%)

Automatic Rollback Triggers:
  - Error rate > 2%
  - Latency p95 > 500ms
  - Any crash/500 error
```

---

## 🔐 Secrets Management

```yaml
# AWS Secrets Manager
Secrets:
  conductores/prod/app:
    SECRET_KEY: "..."
    DATABASE_PASSWORD: "..."
    REDIS_PASSWORD: "..."

  conductores/prod/integrations:
    GEOTAB_PASSWORD: "..."
    CONEKTA_API_KEY: "..."
    METAMAP_API_KEY: "..."
    NEON_CLIENT_SECRET: "..."
    ODOO_PASSWORD: "..."
    OPENAI_API_KEY: "..."
    PINECONE_API_KEY: "..."
    SINOSURE_CERT: "..."

Rotation:
  - Automatic monthly rotation
  - Lambda function updates ECS tasks
  - Zero-downtime rotation
```

---

## 📦 Database Migrations

```yaml
# Alembic migrations en pipeline

Strategy:
  1. Run migrations BEFORE deploying new code
  2. Backward-compatible changes only
  3. Multi-step approach for breaking changes

# .github/workflows/migrate.yml
migrate:
  runs-on: ubuntu-latest
  steps:
    - name: Run Alembic migrations
      run: |
        docker run \
          --env-file .env.prod \
          conductores-backend:latest \
          alembic upgrade head

    - name: Verify migrations
      run: |
        docker run \
          conductores-backend:latest \
          alembic current

Breaking Changes Process:
  Week 1: Add new column (nullable)
  Week 2: Deploy code using new column
  Week 3: Backfill data
  Week 4: Make column non-nullable
  Week 5: Remove old column
```

---

## 🔙 Rollback Strategy

```yaml
Automatic Rollback Triggers:
  - Health check fails > 2 min
  - Error rate > 5%
  - 10+ 500 errors in 1 min

Manual Rollback:
  # Via AWS CLI
  aws ecs update-service \
    --cluster conductores-cluster \
    --service conductores-backend \
    --task-definition conductores-backend:42  # Previous version

  # Via GitHub Actions
  gh workflow run rollback.yml -f version=v1.2.3

Rollback Time: < 5 minutes

Database Rollback:
  # Alembic downgrade
  alembic downgrade -1

  # Only if data-compatible
  # Otherwise: forward-fix
```

---

## 🚀 Siguiente Fase

**→ CORE_FASE7_MONITORING.md**
- Observabilidad completa
- Métricas de negocio
- Alertas y on-call
- Dashboards
