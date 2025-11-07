# GitHub Actions-Native Architecture

## Overview

This document describes the GitHub Actions-native architecture for Factorify, replacing external API servers with reusable workflows and workflow dispatch mechanisms.

## Architecture Principles

### No External Servers
- **No REST APIs**: All communication via GitHub Actions
- **No GraphQL Gateways**: Use GitHub's native GraphQL API
- **No WebSocket Servers**: Use workflow status checks
- **No Database Servers**: Use artifacts and GitHub API

### GitHub Actions as "API"
- Reusable workflows serve as "API endpoints"
- Workflow dispatch acts as "API calls"
- Workflow outputs return "API responses"
- Matrix strategy enables parallel processing

## Core Components

### 1. Reusable Workflows

#### Mod Validation (`reusable-mod-validation.yml`)
**Purpose**: Validate mod structure and content

**Inputs:**
- `mod_path`: Path to mod directory
- `validation_level`: `basic`, `standard`, `strict`

**Outputs:**
- `validation_status`: Pass/fail status
- `validation_report`: URL to validation report artifact

**Usage:**
```yaml
jobs:
  validate:
    uses: owner/repo/.github/workflows/reusable-mod-validation.yml@main
    with:
      mod_path: './mods/my-mod'
      validation_level: 'standard'
```

#### Security Scan (`reusable-security-scan.yml`)
**Purpose**: Scan mod for security vulnerabilities

**Inputs:**
- `mod_path`: Path to mod directory
- `scan_depth`: `surface`, `deep`

**Outputs:**
- `security_status`: Clean/warning/critical
- `vulnerabilities_found`: Count of issues

**Usage:**
```yaml
jobs:
  security:
    uses: owner/repo/.github/workflows/reusable-security-scan.yml@main
    with:
      mod_path: './mods/my-mod'
      scan_depth: 'deep'
```

#### Performance Benchmark (`reusable-performance-benchmark.yml`)
**Purpose**: Measure mod performance impact

**Inputs:**
- `mod_path`: Path to mod directory
- `benchmark_type`: `startup`, `runtime`, `full`

**Outputs:**
- `benchmark_score`: Performance score (0-100)
- `benchmark_report`: URL to benchmark report

**Usage:**
```yaml
jobs:
  benchmark:
    uses: owner/repo/.github/workflows/reusable-performance-benchmark.yml@main
    with:
      mod_path: './mods/my-mod'
      benchmark_type: 'runtime'
```

### 2. Orchestration Workflows

#### Cross-Repository Orchestration (`cross-repo-orchestration.yml`)
**Purpose**: Coordinate multiple analysis workflows

**Features:**
- Parallel execution of validation, security, benchmark
- Conditional workflow execution
- Aggregated summary generation
- Status reporting

**Usage:**
```yaml
# Trigger from another repository
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/owner/repo/actions/workflows/cross-repo-orchestration.yml/dispatches \
  -d '{"ref":"main","inputs":{"mod_path":"./my-mod"}}'
```

### 3. Discord Integration Workflows

#### Mod Analysis (`mod-analysis.yml`)
**Trigger**: Discord bot file upload (.zip)

**Process:**
1. Download mod archive
2. Extract and validate structure
3. Run analysis checks
4. Generate detailed report
5. Post results via Discord webhook

#### Lua Validation (`lua-validation.yml`)
**Trigger**: Discord bot file upload (.lua)

**Process:**
1. Download Lua file
2. Syntax validation
3. Static analysis (luacheck)
4. Pattern detection
5. Post results via Discord webhook

## Cross-Repository Communication

### Method 1: Workflow Dispatch
**Purpose**: Trigger workflows in other repositories

```javascript
const { Octokit } = require('@octokit/rest');
const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });

await octokit.actions.createWorkflowDispatch({
  owner: 'target-owner',
  repo: 'target-repo',
  workflow_id: 'my-workflow.yml',
  ref: 'main',
  inputs: {
    param1: 'value1',
    param2: 'value2'
  }
});
```

### Method 2: Reusable Workflows
**Purpose**: Share workflow logic across repositories

```yaml
# In repository A
jobs:
  shared-logic:
    uses: organization/shared-workflows/.github/workflows/reusable.yml@v1
    with:
      input1: 'value1'
```

### Method 3: Workflow Status Polling
**Purpose**: Monitor workflow execution

```javascript
const runs = await octokit.actions.listWorkflowRuns({
  owner: 'owner',
  repo: 'repo',
  workflow_id: 'workflow.yml',
  status: 'in_progress'
});
```

### Method 4: Artifacts as Data Transfer
**Purpose**: Share data between workflows

```yaml
# Upload in workflow 1
- uses: actions/upload-artifact@v3
  with:
    name: analysis-data
    path: data.json

# Download in workflow 2
- uses: actions/download-artifact@v3
  with:
    name: analysis-data
```

## Authentication Options

### Default: No Authentication Required
**For internal GitHub Actions:**
- Workflows use repository secrets automatically
- No explicit authentication needed
- `GITHUB_TOKEN` provided automatically
- Sufficient for same-organization repos

```yaml
jobs:
  my-job:
    steps:
      - uses: actions/checkout@v4
      # ${{ secrets.GITHUB_TOKEN }} available automatically
```

### Optional: GitHub App Authentication
**For external/public API access:**

Enable authentication:
```javascript
const optionalAuth = require('./authentication/optional_auth');

await optionalAuth.initialize({
  enabled: true,
  githubAppConfig: {
    appId: process.env.GITHUB_APP_ID,
    privateKey: process.env.GITHUB_APP_PRIVATE_KEY
  }
});

const octokit = await optionalAuth.getOctokit('owner', 'repo');
```

Disable authentication (default):
```javascript
await optionalAuth.initialize({
  enabled: false,
  githubToken: process.env.GITHUB_TOKEN
});
```

## Worker Pool Concept

### Matrix Strategy for Parallelization
```yaml
jobs:
  analyze:
    strategy:
      matrix:
        mod: [mod1, mod2, mod3, mod4]
        include:
          - mod: mod1
            validation_level: strict
          - mod: mod2
            validation_level: standard
    runs-on: ubuntu-latest
    steps:
      - name: Analyze ${{ matrix.mod }}
        run: ./analyze.sh ${{ matrix.mod }}
```

### Self-Hosted Runners
**For dedicated capacity:**

```yaml
jobs:
  my-job:
    runs-on: [self-hosted, factorify-runner]
    steps:
      - name: Use dedicated runner
        run: echo "Running on Factorify runner"
```

## Advantages Over External API Servers

### Cost
- ✅ No server hosting costs
- ✅ Free GitHub Actions minutes (public repos)
- ✅ No database hosting needed
- ✅ No CDN/load balancer costs

### Maintenance
- ✅ No server updates/patches
- ✅ No database backups
- ✅ No SSL certificate management
- ✅ Automatic scaling by GitHub

### Security
- ✅ GitHub-managed infrastructure
- ✅ Built-in secrets management
- ✅ Audit logs included
- ✅ No exposed API endpoints

### Reliability
- ✅ GitHub's 99.9% uptime SLA
- ✅ Automatic retries
- ✅ Built-in monitoring
- ✅ Status page included

## Migration from External API

### Before (External API Server)
```javascript
// REST API endpoint
app.post('/api/analyze', async (req, res) => {
  const result = await analyzeMod(req.body.modPath);
  res.json(result);
});

// Client call
const response = await fetch('https://api.factorify.dev/analyze', {
  method: 'POST',
  body: JSON.stringify({ modPath: './mod' })
});
```

### After (GitHub Actions)
```javascript
// Trigger workflow
await octokit.actions.createWorkflowDispatch({
  owner: 'factorify',
  repo: 'actions',
  workflow_id: 'analyze.yml',
  ref: 'main',
  inputs: { mod_path: './mod' }
});

// Check status
const runs = await octokit.actions.listWorkflowRuns({
  owner: 'factorify',
  repo: 'actions',
  workflow_id: 'analyze.yml'
});
```

## Best Practices

### 1. Input Validation
Always validate workflow inputs:
```yaml
on:
  workflow_dispatch:
    inputs:
      mod_path:
        required: true
        type: string
        description: 'Must be a valid path'
```

### 2. Timeout Configuration
Set appropriate timeouts:
```yaml
jobs:
  analyze:
    timeout-minutes: 30
    runs-on: ubuntu-latest
```

### 3. Error Handling
Use `continue-on-error` and `if: always()`:
```yaml
steps:
  - name: Analysis
    continue-on-error: true
  
  - name: Report results
    if: always()
    run: ./report.sh
```

### 4. Artifact Cleanup
Configure retention:
```yaml
- uses: actions/upload-artifact@v3
  with:
    name: results
    path: results/
    retention-days: 7
```

### 5. Concurrency Control
Prevent duplicate runs:
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

## Example: Complete Integration

```yaml
# In discord-bot repository
name: Discord Triggered Analysis

on:
  workflow_dispatch:
    inputs:
      file_url: { required: true, type: string }
      ticket_id: { required: true, type: string }

jobs:
  validate:
    uses: factorify/workflows/.github/workflows/reusable-mod-validation.yml@v1
    with:
      mod_path: './temp-mod'
      validation_level: 'standard'

  security:
    uses: factorify/workflows/.github/workflows/reusable-security-scan.yml@v1
    with:
      mod_path: './temp-mod'

  report:
    needs: [validate, security]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Send to Discord
        env:
          WEBHOOK_URL: ${{ secrets.DISCORD_WEBHOOK_URL }}
        run: |
          curl -X POST "$WEBHOOK_URL" \
            -d "Validation: ${{ needs.validate.result }}"
```

## Monitoring and Observability

### GitHub Actions Dashboard
- View all workflow runs
- Filter by status, branch, trigger
- Download logs and artifacts

### Workflow Status Badges
```markdown
![Analysis](https://github.com/owner/repo/actions/workflows/analyze.yml/badge.svg)
```

### Metrics Collection
```yaml
- name: Collect metrics
  run: |
    echo "duration_seconds=$SECONDS" >> metrics.txt
    echo "files_analyzed=$COUNT" >> metrics.txt

- uses: actions/upload-artifact@v3
  with:
    name: metrics
    path: metrics.txt
```

## Conclusion

This GitHub Actions-native architecture provides:
- Zero infrastructure costs
- Automatic scaling
- Built-in security and monitoring
- Seamless Discord integration
- Optional authentication for future expansion

All without maintaining external servers.
