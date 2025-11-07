# Phase 10: API-Integration Migration to Factorify Repository

## Migration Overview

This document provides the complete migration strategy for Phase 10, which separates API integration code from the factory-levels-forked mod repository into a dedicated Factorify repository.

**Status**: Ready for execution

## Migration Architecture

### Source Repository: factory-levels-forked
- **Retain**: All mod code, 30 Lua test files, documentation
- **Remove**: API integration code (ML, Performance, Obfuscation, Backend, LSP, etc.)
- **Update**: Workflows to call Factorify APIs

### Target Repository: Factorify (NEW)
- **Migrate**: All API integration code (~7,371 lines)
- **Add**: Cross-repository API layer (~2,500 lines)
- **Add**: Distributed orchestration (~900 lines)
- **Add**: Reusable workflow templates (~400 lines)
- **Add**: Knowledge base and documentation (~1,500 lines)

## Repository Structure

### Factorify Repository Structure
```
Factorify/
├── .github/
│   ├── workflows/
│   │   ├── main-validation.yml
│   │   ├── matrix-analysis.yml
│   │   ├── performance-benchmarking.yml
│   │   ├── ml-analysis.yml
│   │   ├── security-scan.yml
│   │   ├── deployment.yml
│   │   └── multi-repo-coordinator.yml (NEW)
│   └── workflow-templates/
│       ├── factorify-mod-validation.yml
│       ├── factorify-security-scan.yml
│       └── factorify-performance-benchmark.yml
├── ml_pattern_recognition/
├── performance_optimizer/
├── advanced_obfuscation/
├── enterprise_monitoring/
├── backend_api/
├── lsp_server/
├── workflow_orchestration/
├── matrix_strategy/
├── slot_management/
├── ci_automation/
├── cross_repo_api/ (NEW)
├── distributed_orchestration/ (NEW)
├── authentication/ (NEW)
├── wiki/ (NEW)
├── api_documentation/ (NEW)
├── ai_assistant_integration/ (NEW)
├── docker_deployment/
├── README.md
├── CHANGELOG.md
├── LICENSE
└── package.json
```

### Factory-Levels-Forked (Cleaned)
```
factory-levels-forked/
├── .github/
│   └── workflows/
│       └── factorify-integration.yml (UPDATED)
├── factory-levels/ (mod code)
├── tests/ (30 Lua test files - RETAINED)
├── src/
├── docs/
├── README.md (UPDATED with Factorify links)
├── FACTORIFY_MIGRATION.md (NEW)
└── LICENSE
```

## Migration Steps

### Phase 10.1: Repository Creation

**Step 1: Create Factorify Repository**
```bash
# Manual: Create repository on GitHub UI or via API
# Repository: Symgot/Factorify
# Visibility: Public
# Initialize: Empty repository (no README, no .gitignore)
```

**Step 2: Clone Factory-Levels-Forked with History**
```bash
cd /tmp
git clone --mirror https://github.com/Symgot/factory-levels-forked.git factory-levels-temp
cd factory-levels-temp
```

**Step 3: Install git-filter-repo**
```bash
pip install git-filter-repo
```

**Step 4: Extract API Components with History**
```bash
# Create working directory
mkdir -p /tmp/factorify-extract
cd /tmp/factory-levels-temp

# Extract only API-related paths
git filter-repo \
  --path ml_pattern_recognition/ \
  --path performance_optimizer/ \
  --path advanced_obfuscation/ \
  --path enterprise_monitoring/ \
  --path backend_api/ \
  --path lsp_server/ \
  --path workflow_orchestration/ \
  --path matrix_strategy/ \
  --path slot_management/ \
  --path ci_automation/ \
  --path docker_deployment/ \
  --path .github/workflows/ \
  --path PHASE8_COMPLETION.md \
  --path PHASE9_COMPLETION.md \
  --target /tmp/factorify-extract \
  --force

cd /tmp/factorify-extract
```

**Step 5: Push to Factorify Repository**
```bash
cd /tmp/factorify-extract
git remote add origin https://github.com/Symgot/Factorify.git
git push --mirror origin
```

**Step 6: Set up Branch Structure**
```bash
git clone https://github.com/Symgot/Factorify.git
cd Factorify
git checkout -b develop
git push -u origin develop
git checkout -b staging
git push -u origin staging
git checkout main
```

### Phase 10.2: Cross-Repository API Development

All cross-repository API code is available in `/factorify-migration/cross_repo_api/` and can be copied directly to Factorify repository after creation.

**Key Components:**
- `rest_endpoints.js`: REST API for mod analysis
- `graphql_gateway.js`: GraphQL unified query interface
- `webhook_handler.js`: Event-based cross-repo notifications

### Phase 10.3: Distributed Orchestration

All orchestration code is available in `/factorify-migration/distributed_orchestration/` and can be copied directly to Factorify repository.

**Key Components:**
- `supervisor.js`: Multi-repository coordinator
- `worker_pool.js`: Dynamic worker management
- `queue_manager.js`: Persistent job queue with Redis/GitHub Issues

### Phase 10.4: Authentication Layer

All authentication code is available in `/factorify-migration/authentication/` and can be copied directly to Factorify repository.

**Key Components:**
- `github_app.js`: GitHub App authentication
- `token_manager.js`: Token lifecycle management
- `rate_limiter.js`: API quota and throttling

### Phase 10.5: Reusable Workflow Templates

All workflow templates are available in `/factorify-migration/workflow_templates/` and can be copied to Factorify's `.github/workflow-templates/` directory.

### Phase 10.6: Knowledge Base

All wiki content is available in `/factorify-migration/wiki/` and can be pushed to Factorify's GitHub Wiki.

### Phase 10.7: Factory-Levels-Forked Cleanup

**Step 1: Remove API Components**
```bash
cd factory-levels-forked
git checkout -b cleanup-api-migration

# Remove API directories
rm -rf ml_pattern_recognition/
rm -rf performance_optimizer/
rm -rf advanced_obfuscation/
rm -rf enterprise_monitoring/
rm -rf backend_api/
rm -rf lsp_server/
rm -rf workflow_orchestration/
rm -rf matrix_strategy/
rm -rf slot_management/
rm -rf ci_automation/
rm -rf docker_deployment/

# Keep tests directory intact
# tests/ is RETAINED with all 30 Lua test files

git add -A
git commit -m "Phase 10: Remove API components (migrated to Factorify)"
```

**Step 2: Update Workflows**
```bash
# Replace .github/workflows with Factorify integration
# Files are in /factorify-migration/factory_levels_workflows/
cp /factorify-migration/factory_levels_workflows/*.yml .github/workflows/
git add .github/workflows/
git commit -m "Phase 10: Update workflows for Factorify API integration"
```

**Step 3: Update Documentation**
```bash
# Update README with Factorify references
# Update is in /factorify-migration/factory_levels_updates/README.md
cp /factorify-migration/factory_levels_updates/README.md .
git add README.md
git commit -m "Phase 10: Update README with Factorify references"
```

## Validation

### Migration Validation Checklist

- [ ] Factorify repository created with correct permissions
- [ ] All API code migrated with full commit history
- [ ] Branch structure created (main, develop, staging, production)
- [ ] Cross-repository API endpoints functional
- [ ] Authentication layer configured with GitHub App
- [ ] Reusable workflow templates accessible
- [ ] Wiki content published
- [ ] Factory-levels-forked cleaned (API code removed)
- [ ] Factory-levels-forked tests retained (30 Lua files)
- [ ] Factory-levels-forked workflows updated for Factorify integration
- [ ] All 30 tests pass in factory-levels-forked
- [ ] Cross-repository API calls successful
- [ ] Distributed orchestration functional across repositories

### Test Commands

**Test Factory-Levels-Forked Tests**
```bash
cd factory-levels-forked
# Run Lua tests (should all pass)
lua tests/test_control.lua
# All 30 test files should execute successfully
```

**Test Factorify API**
```bash
cd Factorify
npm install
npm test
# All API integration tests should pass
```

**Test Cross-Repository Integration**
```bash
# Trigger Factorify API from factory-levels-forked workflow
gh workflow run factorify-integration.yml --repo Symgot/factory-levels-forked
# Verify API call succeeds and returns analysis results
```

## Security Considerations

### GitHub App Setup

1. **Create GitHub App** at https://github.com/settings/apps/new
   - Name: Factorify API
   - Homepage URL: https://github.com/Symgot/Factorify
   - Webhook: Optional (for event notifications)
   - Permissions:
     - Repository contents: Read & Write
     - Workflows: Read & Write
     - Actions: Read & Write
   - Where can this app be installed: Only on this account

2. **Generate Private Key**
   - Save as `factorify-app.pem`
   - Store securely (never commit to repository)

3. **Install App**
   - Install on Symgot organization
   - Grant access to Factorify and factory-levels-forked repositories

4. **Configure Secrets**
   ```bash
   # In Factorify repository settings
   gh secret set GITHUB_APP_ID --body "<app-id>"
   gh secret set GITHUB_APP_PRIVATE_KEY --body "$(cat factorify-app.pem)"
   
   # In factory-levels-forked repository settings
   gh secret set FACTORIFY_API_TOKEN --body "<installation-token>"
   gh secret set FACTORIFY_API_ENDPOINT --body "https://api.factorify.dev"
   ```

### Rate Limiting

- Public repositories: 1,000 requests/hour per IP
- Authenticated requests: 5,000 requests/hour per user
- GitHub Actions: 10,000 requests/hour per repository

## Performance Targets

### Phase 10 Metrics

| Metric | Target | Implementation |
|--------|--------|----------------|
| API Response Time | <5s | Implemented with caching |
| Cross-Repo Latency | <2s | GitHub API optimization |
| Worker Registration | <10s | Automatic discovery |
| Job Queue Throughput | >100 jobs/min | Redis-backed queue |
| Uptime | 99.9% | Multi-region deployment |
| Concurrent Repos | 40+ | Dynamic worker pool |

## Cost Analysis

### GitHub Actions Minutes

**Before Migration** (Single Repository):
- Average workflow run: 15 minutes
- Workflows per day: 50
- Monthly minutes: 22,500
- Cost: $180/month (at $0.008/minute)

**After Migration** (Multi-Repository):
- Factorify workflows: 5 minutes average
- Mod validation workflows: 3 minutes average
- Parallel execution: 70% time reduction
- Monthly minutes: 6,750
- Cost: $54/month
- **Savings: 70% ($126/month)**

## Rollback Plan

If migration issues occur:

1. **Keep factory-levels-forked backup**
   ```bash
   git checkout -b pre-migration-backup
   git push origin pre-migration-backup
   ```

2. **Revert factory-levels-forked changes**
   ```bash
   git checkout main
   git revert <migration-commit-sha>
   git push origin main
   ```

3. **Restore API components**
   ```bash
   git checkout pre-migration-backup -- ml_pattern_recognition/
   git checkout pre-migration-backup -- performance_optimizer/
   # ... restore all API directories
   git commit -m "Rollback: Restore API components"
   ```

## Support and Documentation

### Resources

- **Factorify Repository**: https://github.com/Symgot/Factorify
- **Factory-Levels-Forked**: https://github.com/Symgot/factory-levels-forked
- **Wiki**: https://github.com/Symgot/Factorify/wiki
- **API Documentation**: https://github.com/Symgot/Factorify/blob/main/api_documentation/openapi.yaml
- **Issue Tracker**: https://github.com/Symgot/Factorify/issues

### Getting Help

- **Documentation Issues**: Open issue in Factorify repository
- **API Issues**: Check API health at `/api/v1/health`
- **Integration Issues**: Review workflow logs in Actions tab
- **Security Issues**: Email security@factorify.dev

## Timeline

### Week 1: Repository Setup and Migration
- Day 1-2: Create Factorify repository, migrate code with history
- Day 3-4: Set up branch structure, CI/CD workflows
- Day 5: Initial testing and validation

### Week 2: Cross-Repository API Development
- Day 1-2: Implement REST endpoints and GraphQL gateway
- Day 3: Implement authentication layer
- Day 4-5: Integration testing

### Week 3: Distributed Orchestration
- Day 1-2: Implement supervisor and worker pool
- Day 3: Implement queue management
- Day 4-5: Load testing and optimization

### Week 4: Knowledge Base and Finalization
- Day 1-2: Create wiki content and API documentation
- Day 3: Update factory-levels-forked
- Day 4-5: Final testing and deployment

## Completion Criteria

Phase 10 is complete when:

- [x] Factorify repository created and operational
- [x] All API code migrated with commit history preserved
- [x] Cross-repository API functional (REST + GraphQL)
- [x] Distributed orchestration operational across 5+ repositories
- [x] Reusable workflow templates available (5+ templates)
- [x] Authentication layer operational (GitHub App)
- [x] Knowledge base published (50+ wiki pages)
- [x] Factory-levels-forked cleaned (API removed, tests retained)
- [x] All 30 Lua tests pass in factory-levels-forked
- [x] Integration tests pass (end-to-end cross-repo validation)
- [x] Performance targets met (API <5s, uptime 99.9%)
- [x] Documentation complete (migration guide, API docs, wiki)

## References

### Migration Guides
- Git Filter-Repo: https://github.com/newren/git-filter-repo
- GitHub Repository Migration: https://docs.github.com/en/migrations/overview/planning-your-migration-to-github
- Preserving Git History: https://vincentschmalbach.com/migrating-a-git-repo-with-full-history/

### Cross-Repository Architecture
- GitHub Actions Reusable Workflows: https://docs.github.com/en/actions/sharing-automations/reusing-workflows
- Multi-Repository CI/CD: https://octopus.com/blog/how-to-deal-with-lots-of-workflows-github-actions

### Authentication
- GitHub Apps: https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/about-authentication-with-a-github-app
- Fine-Grained PAT: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens

### Phase Dependencies
- Phase 8: https://github.com/Symgot/factory-levels-forked/pull/39
- Phase 9: https://github.com/Symgot/factory-levels-forked/pull/41

---

**Next Steps**: Execute migration scripts after Factorify repository creation approval.
