# Factorify API Reference

Complete reference for the Factorify REST and GraphQL APIs.

## Base URL

```
https://api.factorify.dev
```

## Authentication

All API requests require authentication using a Bearer token:

```http
Authorization: Bearer YOUR_API_TOKEN
```

## REST API Endpoints

### 1. Analyze Mod

Submit a mod for comprehensive analysis.

**Endpoint**: `POST /api/v1/analyze/mod`

**Request Body**:
```json
{
  "repository": "owner/repo",
  "url": "https://github.com/owner/repo/blob/main/control.lua",
  "type": "full|syntax|ml|performance|security",
  "options": {
    "ml": true,
    "performance": true,
    "obfuscation": true,
    "timeout": 300000,
    "priority": "critical|high|normal|low"
  }
}
```

**Response**: `202 Accepted`
```json
{
  "jobId": "job_1699876543_abc123",
  "status": "queued",
  "estimatedTime": "2-5 minutes",
  "statusUrl": "/api/v1/status/job_1699876543_abc123",
  "message": "Analysis job queued successfully"
}
```

**Error Responses**:
- `400 Bad Request`: Missing required fields
- `401 Unauthorized`: Invalid or missing token
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

---

### 2. Get Job Status

Check the status of an analysis job.

**Endpoint**: `GET /api/v1/status/:jobId`

**Response**: `200 OK`
```json
{
  "jobId": "job_1699876543_abc123",
  "status": "queued|running|completed|failed",
  "progress": 75,
  "createdAt": "2024-11-07T10:30:00Z",
  "updatedAt": "2024-11-07T10:32:00Z",
  "result": {
    "ml": { ... },
    "performance": { ... },
    "obfuscation": { ... }
  }
}
```

**Status Values**:
- `queued`: Job is in the queue
- `running`: Job is being processed
- `completed`: Job finished successfully
- `failed`: Job failed with error

---

### 3. ML Prediction

Run ML pattern recognition on code.

**Endpoint**: `POST /api/v1/ml/predict`

**Request Body**:
```json
{
  "code": "local function example() ... end",
  "modelType": "pattern_recognition|anomaly_detection|quality_prediction"
}
```

**Response**: `200 OK`
```json
{
  "modelType": "pattern_recognition",
  "result": {
    "predictedClass": "entity_manipulation",
    "confidence": 0.92,
    "features": [0.1, 0.2, ...],
    "alternatives": [
      {"class": "recipe_handling", "confidence": 0.05},
      {"class": "prototype_definition", "confidence": 0.03"}
    ]
  },
  "inferenceTime": 42,
  "timestamp": "2024-11-07T10:30:00Z"
}
```

**ML Classes**:
1. `entity_manipulation`: Entity creation/modification
2. `recipe_handling`: Recipe and crafting logic
3. `prototype_definition`: Prototype definitions
4. `event_handling`: Event registration and callbacks
5. `data_processing`: Data structures and algorithms
6. `ui_interaction`: GUI and player interactions
7. `multiplayer_sync`: Multiplayer synchronization
8. `optimization`: Performance optimization code
9. `modding_api`: Modding API usage
10. `utility_functions`: Helper and utility functions

---

### 4. Performance Benchmark

Run performance benchmarks on code.

**Endpoint**: `POST /api/v1/performance/benchmark`

**Request Body**:
```json
{
  "code": "local function example() ... end",
  "benchmarkType": "parse|execute|memory",
  "iterations": 100
}
```

**Response**: `200 OK`
```json
{
  "benchmarkType": "parse",
  "iterations": 100,
  "result": {
    "mean": 15.3,
    "median": 15.1,
    "p95": 18.7,
    "p99": 21.2,
    "min": 12.5,
    "max": 25.3,
    "stdDev": 2.1
  },
  "timestamp": "2024-11-07T10:30:00Z"
}
```

**Benchmark Types**:
- `parse`: Parse time measurement
- `execute`: Execution time (simulated)
- `memory`: Memory usage analysis

---

### 5. Obfuscation Detection

Detect code obfuscation techniques.

**Endpoint**: `POST /api/v1/obfuscation/detect`

**Request Body**:
```json
{
  "code": "local function example() ... end",
  "detailed": true
}
```

**Response**: `200 OK`
```json
{
  "obfuscationScore": 12,
  "isObfuscated": false,
  "confidence": 0.95,
  "techniques": [],
  "cfgMetrics": {
    "cyclomaticComplexity": 3,
    "maxDepth": 2,
    "nodeCount": 5
  },
  "entropyAnalysis": {
    "overallEntropy": 4.2,
    "stringEntropy": 3.8,
    "identifierEntropy": 4.5
  },
  "timestamp": "2024-11-07T10:30:00Z"
}
```

**Obfuscation Techniques Detected**:
- `string_encryption`: Encrypted string literals
- `control_flow_flattening`: Flattened control flow
- `dead_code_injection`: Injected dead code
- `identifier_renaming`: Renamed identifiers
- `constant_folding`: Folded constants

**Score Interpretation**:
- `0-20`: No obfuscation
- `21-45`: Minor obfuscation
- `46-70`: Moderate obfuscation
- `71-100`: Heavy obfuscation

---

### 6. Health Check

Check API health status.

**Endpoint**: `GET /api/v1/health`

**Response**: `200 OK` (healthy) or `503 Service Unavailable` (unhealthy)
```json
{
  "status": "healthy",
  "timestamp": "2024-11-07T10:30:00Z",
  "version": "1.0.0",
  "services": {
    "ml": {"status": "healthy", "latency": 0},
    "performance": {"status": "healthy", "latency": 0},
    "obfuscation": {"status": "healthy", "latency": 0},
    "queue": {"status": "healthy", "pendingJobs": 0}
  },
  "uptime": 86400,
  "memory": {
    "rss": 134217728,
    "heapTotal": 67108864,
    "heapUsed": 33554432
  }
}
```

---

### 7. Trigger Workflow

Trigger a workflow in a target repository.

**Endpoint**: `POST /api/v1/workflow/trigger`

**Request Body**:
```json
{
  "targetRepository": "owner/repo",
  "workflow": "factorify-validation.yml",
  "ref": "main",
  "inputs": {
    "analysis_depth": "comprehensive"
  },
  "priority": "high"
}
```

**Response**: `202 Accepted`
```json
{
  "workflowId": "workflow_1699876543_abc123",
  "status": "queued",
  "statusUrl": "/api/v1/status/workflow_1699876543_abc123",
  "message": "Workflow trigger queued successfully"
}
```

---

## GraphQL API

### Endpoint

```
POST /api/v1/graphql
```

### Schema

#### Query: analyzeModFile

```graphql
query {
  analyzeModFile(
    url: "https://github.com/owner/repo/blob/main/control.lua"
    options: {
      ml: true
      performance: true
      obfuscation: true
    }
  ) {
    ml {
      class
      confidence
      features
    }
    performance {
      parseTime
      cacheHitRate
      memoryUsage
      throughput
    }
    obfuscation {
      score
      isObfuscated
      confidence
      techniques
    }
    quality
    timestamp
  }
}
```

#### Query: getJobStatus

```graphql
query {
  getJobStatus(jobId: "job_1699876543_abc123") {
    id
    status
    progress
    createdAt
    updatedAt
    result {
      ml { ... }
      performance { ... }
      obfuscation { ... }
      quality
    }
    error
  }
}
```

#### Mutation: submitModForAnalysis

```graphql
mutation {
  submitModForAnalysis(input: {
    repository: "owner/repo"
    type: "full"
    options: {
      ml: true
      performance: true
      obfuscation: true
      priority: "high"
    }
  }) {
    id
    status
    statusUrl
    estimatedTime
    message
  }
}
```

---

## Rate Limits

Rate limit headers are included in all responses:

```http
X-RateLimit-Remaining-Hourly: 4950
X-RateLimit-Remaining-Minute: 98
X-RateLimit-Remaining-Concurrent: 48
```

When rate limit is exceeded, you'll receive:

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 60

{
  "error": "Too Many Requests",
  "message": "Rate limit exceeded: minute_limit_exceeded",
  "retryAfter": 60,
  "limits": {
    "hourlyRemaining": 0,
    "minuteRemaining": 0,
    "burstRemaining": 0,
    "concurrentRemaining": 0
  },
  "code": "RATE_LIMIT_EXCEEDED"
}
```

---

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `MISSING_AUTH` | 401 | Missing or invalid authorization header |
| `INVALID_TOKEN` | 401 | Token is invalid or expired |
| `MISSING_SOURCE` | 400 | Repository or URL not provided |
| `MISSING_CODE` | 400 | Code content is required |
| `INVALID_MODEL` | 400 | Unknown ML model type |
| `TOO_MANY_ITERATIONS` | 400 | Exceeded max iterations (1000) |
| `JOB_NOT_FOUND` | 404 | Job ID not found |
| `RATE_LIMIT_EXCEEDED` | 429 | Rate limit exceeded |
| `ANALYSIS_ERROR` | 500 | Internal analysis error |
| `PREDICTION_ERROR` | 500 | ML prediction error |
| `BENCHMARK_ERROR` | 500 | Benchmarking error |
| `DETECTION_ERROR` | 500 | Obfuscation detection error |
| `WORKFLOW_ERROR` | 500 | Workflow trigger error |

---

## SDKs and Libraries

### JavaScript/Node.js

```bash
npm install @factorify/client
```

```javascript
const { FactorifyClient } = require('@factorify/client');

const client = new FactorifyClient({
  apiToken: process.env.FACTORIFY_API_TOKEN
});

const result = await client.analyzeFile({
  url: 'https://github.com/user/mod/blob/main/control.lua'
});
```

### Python

```bash
pip install factorify-client
```

```python
from factorify import FactorifyClient

client = FactorifyClient(api_token=os.getenv('FACTORIFY_API_TOKEN'))

result = client.analyze_file(
    url='https://github.com/user/mod/blob/main/control.lua'
)
```

### GitHub Actions

See [Reusable Workflows](Reusable-Workflows.md) for GitHub Actions integration.

---

## Support

For API support, please:

1. Check the [FAQ](FAQ.md)
2. Search [existing issues](https://github.com/Symgot/Factorify/issues)
3. Open a [new issue](https://github.com/Symgot/Factorify/issues/new)
4. Join our [Discord community](https://discord.gg/factorify)

---

**API Version**: v1.0.0  
**Last Updated**: 2024-11-07
