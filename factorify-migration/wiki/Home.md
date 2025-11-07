# Factorify - Cross-Repository API for Factorio Mod Analysis

Welcome to **Factorify**, the enterprise-grade API platform for Factorio mod validation, analysis, and security scanning.

## What is Factorify?

Factorify provides powerful ML-based pattern recognition, performance optimization, and obfuscation detection capabilities as a service for Factorio mod developers and CI/CD pipelines.

### Key Features

- **🤖 ML Pattern Recognition**: 10-class neural network for code pattern analysis
- **⚡ Performance Optimization**: Sub-20ms parse times with intelligent caching
- **🔒 Security Scanning**: Advanced obfuscation detection and security analysis
- **🌐 Cross-Repository Integration**: REST and GraphQL APIs for multi-repo workflows
- **📊 Distributed Orchestration**: Multi-repository supervisor-worker coordination
- **📚 Reusable Workflows**: Pre-configured GitHub Actions templates

## Quick Start

### 1. Register Your Repository

Contact the Factorify team to register your repository and receive an API token:

```bash
gh secret set FACTORIFY_API_TOKEN --body "<your-token>"
```

### 2. Add Workflow Template

Create `.github/workflows/factorify-validation.yml`:

```yaml
name: Factorify Validation

on:
  push:
    branches: [main]
    paths: ['**.lua']

jobs:
  validate:
    uses: Symgot/Factorify/.github/workflows/factorify-mod-validation.yml@v1
    secrets:
      FACTORIFY_API_TOKEN: ${{ secrets.FACTORIFY_API_TOKEN }}
```

### 3. Run Analysis

Push your changes or manually trigger the workflow:

```bash
git push origin main
# or
gh workflow run factorify-validation.yml
```

## Architecture

```
┌─────────────────┐
│ Your Repository │
└────────┬────────┘
         │ API Calls
         ▼
┌─────────────────┐
│   Factorify     │
│   REST/GraphQL  │
└────────┬────────┘
         │
    ┌────┴────┬─────────┬────────────┐
    ▼         ▼         ▼            ▼
┌────────┐ ┌─────┐ ┌──────────┐ ┌────────┐
│   ML   │ │Perf │ │Obfuscate │ │Monitor │
│ Engine │ │ Opt │ │ Analyzer │ │  ing   │
└────────┘ └─────┘ └──────────┘ └────────┘
```

## API Endpoints

### REST API

- `POST /api/v1/analyze/mod` - Submit mod for analysis
- `GET /api/v1/status/:jobId` - Check analysis status
- `POST /api/v1/ml/predict` - ML pattern recognition
- `POST /api/v1/performance/benchmark` - Performance benchmarking
- `POST /api/v1/obfuscation/detect` - Obfuscation detection
- `GET /api/v1/health` - Health check

### GraphQL API

```graphql
query {
  analyzeModFile(url: "https://github.com/user/mod/blob/main/control.lua") {
    ml {
      class
      confidence
    }
    performance {
      parseTime
      cacheHitRate
    }
    obfuscation {
      score
      isObfuscated
    }
    quality
  }
}
```

## Example Usage

### Analyze a Mod File

```bash
curl -X POST https://api.factorify.dev/api/v1/analyze/mod \
  -H "Authorization: Bearer $FACTORIFY_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "repository": "user/my-factorio-mod",
    "type": "full",
    "options": {
      "ml": true,
      "performance": true,
      "obfuscation": true,
      "priority": "high"
    }
  }'
```

Response:
```json
{
  "jobId": "job_1699876543_abc123",
  "status": "queued",
  "estimatedTime": "2-5 minutes",
  "statusUrl": "/api/v1/status/job_1699876543_abc123"
}
```

### Check Job Status

```bash
curl -X GET https://api.factorify.dev/api/v1/status/job_1699876543_abc123 \
  -H "Authorization: Bearer $FACTORIFY_API_TOKEN"
```

Response:
```json
{
  "jobId": "job_1699876543_abc123",
  "status": "completed",
  "result": {
    "ml": {
      "predictedClass": "entity_manipulation",
      "confidence": 0.92
    },
    "performance": {
      "parseTime": 15.3,
      "cacheHitRate": 0.87
    },
    "obfuscation": {
      "score": 12,
      "isObfuscated": false
    },
    "quality": 95
  }
}
```

## Performance Metrics

| Metric | Target | Typical |
|--------|--------|---------|
| API Response Time | <5s | 2-3s |
| Parse Time | <20ms | 15-18ms |
| ML Inference | <50ms | 35-45ms |
| Cache Hit Rate | >80% | 85-90% |
| Uptime | 99.9% | 99.95% |

## Rate Limits

| Plan | Requests/Hour | Requests/Minute | Concurrent |
|------|---------------|-----------------|------------|
| Free | 1,000 | 50 | 5 |
| Standard | 5,000 | 100 | 20 |
| Enterprise | 10,000 | 200 | 50 |

## Support

- **Documentation**: https://github.com/Symgot/Factorify/wiki
- **API Reference**: https://github.com/Symgot/Factorify/blob/main/api_documentation/openapi.yaml
- **Issues**: https://github.com/Symgot/Factorify/issues
- **Discussions**: https://github.com/Symgot/Factorify/discussions

## Migration Guide

If you're migrating from the factory-levels-forked API integration:

1. Update API endpoint from local to `https://api.factorify.dev`
2. Replace local API modules with REST/GraphQL calls
3. Update GitHub Actions workflows to use reusable templates
4. Configure `FACTORIFY_API_TOKEN` secret

See [PHASE10_MIGRATION_GUIDE.md](../PHASE10_MIGRATION_GUIDE.md) for detailed migration steps.

## Contributing

We welcome contributions! See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](../LICENSE) for details.

---

**Factorify** - Powering the future of Factorio mod development with AI and automation.
