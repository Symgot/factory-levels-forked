# Factorio Mod Validator - Docker Deployment Guide
# Phase 8: Production-Ready Container Deployment

## Quick Start

### 1. Prerequisites
- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM minimum
- 10GB disk space

### 2. Environment Setup

Create `.env` file:
```bash
# Security
JWT_SECRET=your-secure-random-string-here

# Performance
NUM_WORKERS=4

# External Access
ALLOWED_ORIGINS=https://yourdomain.com

# Grafana
GRAFANA_PASSWORD=secure-password-here
```

### 3. Build and Deploy

```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f backend
```

## Service Endpoints

- **Backend API**: http://localhost:3001
  - Health: http://localhost:3001/api/health
  - Docs: http://localhost:3001/api/docs

- **Metrics**: http://localhost:9090/metrics

- **Prometheus**: http://localhost:9091

- **Grafana**: http://localhost:3002
  - Default login: admin/admin (change immediately)

## Production Deployment

### Security Hardening

1. **Change default passwords**:
   ```bash
   JWT_SECRET=$(openssl rand -base64 32)
   GRAFANA_PASSWORD=$(openssl rand -base64 16)
   ```

2. **Enable HTTPS** (use reverse proxy):
   ```nginx
   server {
       listen 443 ssl http2;
       server_name validator.yourdomain.com;
       
       ssl_certificate /path/to/cert.pem;
       ssl_certificate_key /path/to/key.pem;
       
       location / {
           proxy_pass http://localhost:3001;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

3. **Firewall rules**:
   ```bash
   # Allow only necessary ports
   ufw allow 443/tcp
   ufw allow 22/tcp
   ufw deny 3001/tcp  # Block direct API access
   ufw deny 9090/tcp  # Block direct metrics access
   ```

### Resource Limits

Adjust in `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 4G
    reservations:
      cpus: '2'
      memory: 1G
```

### High Availability

For production, use Kubernetes:

```yaml
# kubernetes/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: factorio-validator
spec:
  replicas: 3
  selector:
    matchLabels:
      app: factorio-validator
  template:
    metadata:
      labels:
        app: factorio-validator
    spec:
      containers:
      - name: backend
        image: factorio-validator:8.0.0
        ports:
        - containerPort: 3001
        - containerPort: 9090
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /api/health/live
            port: 3001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health/ready
            port: 3001
          initialDelaySeconds: 10
          periodSeconds: 5
```

## Monitoring and Alerting

### View Metrics

```bash
# API metrics
curl http://localhost:9090/metrics

# Health check
curl http://localhost:3001/api/health
```

### Grafana Dashboards

1. Access Grafana: http://localhost:3002
2. Login with credentials
3. Import dashboard from `grafana-dashboards/`

### Prometheus Alerts

Example alert rule (`prometheus/alerts/api.yml`):

```yaml
groups:
  - name: api_alerts
    interval: 30s
    rules:
      - alert: HighErrorRate
        expr: rate(errors_total[5m]) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }} errors/second"
```

## Maintenance

### Backup

```bash
# Backup volumes
docker run --rm \
  -v factorio-validator_uploads:/data/uploads \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/uploads-$(date +%Y%m%d).tar.gz -C /data/uploads .

# Backup logs
docker run --rm \
  -v factorio-validator_logs:/data/logs \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/logs-$(date +%Y%m%d).tar.gz -C /data/logs .
```

### Update

```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Check health
docker-compose ps
docker-compose logs -f backend
```

### Cleanup

```bash
# Remove old images
docker image prune -a -f

# Remove old logs
docker-compose exec backend find /app/logs -name "*.log" -mtime +30 -delete

# Clean volumes (WARNING: deletes data)
docker-compose down -v
```

## Troubleshooting

### Check logs
```bash
docker-compose logs backend
docker-compose logs prometheus
docker-compose logs grafana
```

### Access container
```bash
docker-compose exec backend sh
```

### Restart service
```bash
docker-compose restart backend
```

### Performance issues
```bash
# Check resource usage
docker stats

# Increase workers
docker-compose up -d --scale backend=2
```

## Performance Tuning

### Node.js Optimization
```bash
# Increase memory limit
NODE_OPTIONS="--max-old-space-size=4096"

# Enable worker threads
NUM_WORKERS=8
```

### Docker Optimization
```bash
# Use overlay2 storage driver
# Enable buildkit
DOCKER_BUILDKIT=1 docker-compose build
```

## Security Checklist

- [ ] Change all default passwords
- [ ] Enable HTTPS with valid certificates
- [ ] Configure firewall rules
- [ ] Set resource limits
- [ ] Enable audit logging
- [ ] Regular security updates
- [ ] Backup strategy in place
- [ ] Monitoring and alerting configured
- [ ] Network segmentation
- [ ] Secrets management (use Docker secrets or Vault)

## Support

For issues or questions:
- GitHub Issues: https://github.com/Symgot/factory-levels-forked/issues
- Documentation: See PHASE8_COMPLETION.md
