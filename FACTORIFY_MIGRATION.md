# Factorify Repository Migration Guide

## Overview

This document provides step-by-step instructions for migrating API-related code from `factory-levels-forked` to the new `Symgot/Factorify` repository while preserving Git history and maintaining test coverage.

## Migration Goals

1. **Selective Migration**: Move only API-related code (~35,000+ lines)
2. **History Preservation**: Maintain full commit history for migrated files
3. **Test Retention**: Keep all 117 tests in factory-levels-forked
4. **Branch Structure**: Establish proper Git flow (main, develop, staging, production)
5. **Tag Migration**: Transfer relevant version tags (v5.0 through v10.0)

## Prerequisites

### Tools Required

```bash
# Install git-filter-repo
pip install git-filter-repo

# Or on macOS
brew install git-filter-repo

# Verify installation
git-filter-repo --version
```

### Repository Setup

1. **Create Factorify Repository on GitHub**
   - Repository name: `Factorify`
   - Visibility: Public
   - License: MIT
   - Initialize: Empty (no README, .gitignore, or license yet)

2. **Backup Current Repository**
```bash
cd /path/to/factory-levels-forked
git clone --mirror . ../factory-levels-forked-backup
```

## Migration Steps

### Step 1: Clone Fresh Copy

```bash
# Create working directory
mkdir -p ~/factorify-migration
cd ~/factorify-migration

# Clone factory-levels-forked with full history
git clone --mirror https://github.com/Symgot/factory-levels-forked.git temp-repo
cd temp-repo
```

### Step 2: Filter API-Related Files

```bash
# Use git-filter-repo to extract API components
git filter-repo \
  --path ml_pattern_recognition/ \
  --path performance_optimizer/ \
  --path advanced_obfuscation/ \
  --path enterprise_monitoring/ \
  --path backend_api/ \
  --path lsp_server/ \
  --path factorify-migration/cross_repo_api/ \
  --path factorify-migration/distributed_orchestration/ \
  --path factorify-migration/authentication/ \
  --path factorify-migration/workflow_templates/ \
  --path factorify-migration/factory_levels_workflows/ \
  --path factorify-migration/ai_assistant_integration/ \
  --path factorify-migration/api_documentation/ \
  --path factorify-migration/wiki/ \
  --path github_actions_integration/ \
  --path authentication/ \
  --path discord_bot/ \
  --path docker_deployment/ \
  --path ci_automation/ \
  --path matrix_strategy/ \
  --path slot_management/ \
  --path workflow_orchestration/ \
  --path .github/workflows/ \
  --path-rename factorify-migration/:. \
  --force
```

### Step 3: Clean Up Migrated Repository

```bash
# Remove .git/refs/original (created by filter-repo)
rm -rf .git/refs/original

# Verify remaining files
git log --oneline --all --graph
```

### Step 4: Restructure for Factorify

```bash
# Create proper branch structure
git branch develop
git branch staging
git branch production

# Switch to main branch
git checkout -b main

# Create Factorify-specific files
cat > README.md << 'EOF'
# Factorify

Advanced Factorio mod analysis platform with ML-powered validation, performance optimization, and security scanning.

## Features

- ML-based pattern recognition
- Performance optimization suggestions
- Obfuscation detection
- API compatibility checking
- Discord bot integration
- GitHub Actions native workflows

## Getting Started

See [Documentation](./wiki/Home.md) for setup instructions.

## License

MIT
EOF

cat > .gitignore << 'EOF'
node_modules/
*.log
.env
.DS_Store
data/
dist/
build/
*.zip
*.tar.gz
EOF

git add README.md .gitignore
git commit -m "chore: Initialize Factorify repository structure"
```

### Step 5: Push to Factorify Repository

```bash
# Add Factorify remote
git remote remove origin
git remote add origin https://github.com/Symgot/Factorify.git

# Push all branches
git push -u origin main
git push origin develop
git push origin staging
git push origin production

# Push all tags
git push origin --tags
```

### Step 6: Verify Migration

```bash
# Clone the new Factorify repository
cd ~/factorify-migration
git clone https://github.com/Symgot/Factorify.git factorify-verify
cd factorify-verify

# Check file structure
tree -L 2

# Verify history preservation
git log --oneline --all --graph | head -50

# Check branches
git branch -a

# Check tags
git tag -l
```

### Step 7: Clean Up Factory-Levels-Forked

```bash
# Go to original factory-levels-forked
cd /path/to/factory-levels-forked

# Create cleanup branch
git checkout -b cleanup-after-migration

# Remove migrated API files (keep tests!)
git rm -r ml_pattern_recognition/
git rm -r performance_optimizer/
git rm -r advanced_obfuscation/
git rm -r enterprise_monitoring/
git rm -r backend_api/
git rm -r lsp_server/
git rm -r factorify-migration/
git rm -r github_actions_integration/
git rm -r authentication/
git rm -r discord_bot/
git rm -r docker_deployment/
git rm -r ci_automation/
git rm -r matrix_strategy/
git rm -r slot_management/
git rm -r workflow_orchestration/

# Keep tests/, factory-levels/, and mod-specific files
# Verify tests remain
ls tests/

# Commit cleanup
git commit -m "chore: Remove API files after migration to Factorify

All API-related code has been migrated to:
https://github.com/Symgot/Factorify

This repository now focuses on Factorio mod code and testing.
Tests remain here for validation purposes."

# Push cleanup
git push origin cleanup-after-migration
```

## Files to Migrate

### Core API Components (~35,000+ lines)

| Directory | Lines | Description |
|-----------|-------|-------------|
| `ml_pattern_recognition/` | ~2,100 | ML-based pattern detection |
| `performance_optimizer/` | ~1,600 | Performance analysis |
| `advanced_obfuscation/` | ~1,850 | Obfuscation detection |
| `enterprise_monitoring/` | ~850 | Monitoring & logging |
| `backend_api/` | ~1,700 | REST API server |
| `lsp_server/` | ~370 | Language server protocol |
| `cross_repo_api/` | ~2,814 | Cross-repo integration |
| `distributed_orchestration/` | ~2,882 | Worker pool management |
| `authentication/` | ~2,085 | GitHub App auth |
| `workflow_templates/` | ~1,980 | Reusable workflows |
| `github_actions_integration/` | ~3,000 | Native GitHub Actions |
| `discord_bot/` | ~4,500 | Discord bot |
| `docker_deployment/` | ~450 | Docker configs |
| `ci_automation/` | ~500 | CI/CD scripts |
| `wiki/` | ~1,464 | Documentation |
| `api_documentation/` | ~1,260 | OpenAPI specs |

**Total: ~35,329 lines**

### Files to Keep in Factory-Levels-Forked

- `tests/` (all 117 test files)
- `factory-levels/` (mod source code)
- `src/` (mod utilities)
- `README.md`
- `LICENSE`
- Phase completion documents (for historical reference)

## Branch Structure

### Factorify Branches

```
main (protected)
├── develop (default branch for development)
├── staging (pre-production testing)
└── production (stable releases)
```

### Branch Protection Rules

**main branch:**
- Require pull request reviews (2 approvals)
- Require status checks to pass
- Require branches to be up to date
- No force pushes
- No deletions

**develop branch:**
- Require pull request reviews (1 approval)
- Require status checks to pass

## Tag Migration

### Version Tags to Transfer

```bash
# Tags from Phases 5-10
v5.0.0  # Phase 5: ML Pattern Recognition
v6.0.0  # Phase 6: Enterprise Monitoring
v7.0.0  # Phase 7: LSP Server
v8.0.0  # Phase 8: AI Assistant Integration
v9.0.0  # Phase 9: Documentation
v10.0.0 # Phase 10: Cross-Repository Orchestration
v11.0.0 # Phase 11: GitHub Actions Native + Discord Bot
```

### Tag Transfer Command

```bash
# In the filtered repository
git tag v11.0.0 -m "Phase 11: GitHub Actions Native Integration & Discord Bot"
git push origin v11.0.0
```

## Post-Migration Tasks

### 1. Update Factory-Levels-Forked README

```markdown
# Factory Levels (Archived for API Development)

**Note**: API development has moved to [Factorify](https://github.com/Symgot/Factorify).

This repository now contains:
- Original Factorio mod source code
- Test suite (117 tests)
- Historical phase completion documents

For mod analysis features, see the Factorify repository.
```

### 2. Create Factorify Integration Workflow

Create `.github/workflows/test-with-factorify.yml` in factory-levels-forked:

```yaml
name: Test with Factorify

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Checkout Factorify
        uses: actions/checkout@v4
        with:
          repository: Symgot/Factorify
          path: factorify
      
      - name: Run Tests
        run: |
          cd tests
          lua test_runner.lua
```

### 3. Update Factorify README

Add comprehensive documentation:
- Installation instructions
- API documentation
- Discord bot setup
- GitHub Actions integration guide

### 4. Configure Factorify Repository Settings

1. **Enable Issues** for bug tracking
2. **Enable Discussions** for community
3. **Configure GitHub Pages** from wiki/
4. **Set up Dependabot** for security updates
5. **Configure branch protection** rules

## Verification Checklist

- [ ] All API files successfully migrated
- [ ] Commit history preserved (check with `git log`)
- [ ] All branches created (main, develop, staging, production)
- [ ] Version tags transferred (v5.0.0 through v11.0.0)
- [ ] Tests remain in factory-levels-forked (117 files)
- [ ] Factorify repository accessible at https://github.com/Symgot/Factorify
- [ ] README updated in both repositories
- [ ] .gitignore properly configured
- [ ] License file present (MIT)
- [ ] No broken file references in migrated code

## Rollback Procedure

If migration fails:

```bash
# Restore from backup
cd ~/factorify-migration
git clone factory-levels-forked-backup factory-levels-forked-restored

# Or delete Factorify repository and restart
```

## Common Issues

### Issue: git-filter-repo not found
**Solution**: Install via `pip install git-filter-repo` or use package manager

### Issue: Permission denied when pushing
**Solution**: Configure GitHub token with repo scope:
```bash
git config credential.helper store
git push # Enter token when prompted
```

### Issue: Large files blocking push
**Solution**: Use Git LFS or remove large files:
```bash
git filter-repo --strip-blobs-bigger-than 100M
```

### Issue: Merge conflicts after cleanup
**Solution**: Resolve conflicts manually or reset to backup

## Support

For migration assistance:
- GitHub Issues: https://github.com/Symgot/Factorify/issues
- Email: (your email)

## Timeline

- **Phase 11.3 Week 1**: Repository setup and migration preparation
- **Phase 11.3 Week 2**: Execute migration with git-filter-repo
- **Phase 11.3 Week 3**: Verification and cleanup
- **Phase 11.3 Week 4**: Documentation updates and integration testing

## Next Steps

After successful migration:

1. Set up CI/CD pipelines in Factorify
2. Configure Discord bot webhooks
3. Deploy GitHub Actions workflows
4. Update documentation with new repository links
5. Archive old API branches in factory-levels-forked

---

**Migration Date**: 2024-11-07  
**Migrated By**: GitHub Copilot Agent  
**Status**: Ready for Execution
