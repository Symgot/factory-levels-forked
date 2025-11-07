# Phase 11 Implementation Guide

## Overview

Phase 11 implements a GitHub Actions-native architecture with Discord bot integration, replacing the external API server approach from Phase 10 with workflow-based orchestration.

## What Changed from Phase 10

### Phase 10 (PR #43)
- ✅ Created migration architecture (~13,500 lines)
- ✅ Designed REST/GraphQL APIs
- ✅ Implemented external server concepts
- ❌ Did not perform repository migration
- ❌ Used external API servers (not GitHub Actions-native)
- ❌ Missing Discord bot integration
- ❌ Authentication not optional

### Phase 11 (This Implementation)
- ✅ GitHub Actions as "API" (reusable workflows)
- ✅ Discord bot with ticket system
- ✅ Optional authentication (default: off)
- ✅ Workflow dispatch for cross-repo communication
- ✅ No external servers required
- ✅ Complete integration examples

## Architecture Changes

### Before: External API Approach
```
Discord/Client -> REST API Server -> Database -> Worker Pool
                      ↓
                GitHub Actions (secondary)
```

### After: GitHub Actions-Native
```
Discord Bot -> Workflow Dispatch -> GitHub Actions (primary)
                                          ↓
                                  Reusable Workflows
                                          ↓
                                     Artifacts
                                          ↓
                                   Discord Webhook
```

## Components Implemented

### 1. Discord Bot (`/discord-bot/`)
**Files Created:**
- `package.json` - Dependencies and scripts
- `.env.example` - Configuration template
- `src/index.js` - Main bot logic
- `src/config/index.js` - Configuration management
- `src/commands/analyze-mod.js` - Ticket creation command
- `src/commands/close-ticket.js` - Ticket closing command
- `src/utils/deploy-commands.js` - Command registration
- `README.md` - Complete documentation

**Features:**
- Private ticket system per user
- File upload handling (.zip, .lua)
- Automatic GitHub Actions workflow triggering
- Size and type validation
- Error handling and reporting

### 2. GitHub Actions Workflows (`/.github/workflows/`)
**Files Created:**
- `mod-analysis.yml` - Full mod archive analysis
- `lua-validation.yml` - Lua syntax and pattern validation
- `reusable-mod-validation.yml` - Reusable validation workflow
- `reusable-security-scan.yml` - Reusable security scanning
- `reusable-performance-benchmark.yml` - Reusable benchmarking
- `cross-repo-orchestration.yml` - Multi-workflow coordinator

**Features:**
- Workflow dispatch triggers
- Reusable workflow pattern
- Matrix strategy support
- Artifact generation
- Discord webhook integration

### 3. Optional Authentication (`/factorify-migration/authentication/`)
**Files Created:**
- `optional_auth.js` - Configurable authentication wrapper

**Features:**
- Default: No authentication (public API)
- Optional: GitHub App authentication
- Token-based fallback
- Automatic mode detection
- Metrics and monitoring

### 4. Documentation
**Files Created:**
- `GITHUB_ACTIONS_ARCHITECTURE.md` - Complete architecture guide
- `PHASE11_IMPLEMENTATION.md` - This file
- `discord-bot/README.md` - Discord bot documentation

## Installation

### Discord Bot Setup

1. **Install dependencies:**
```bash
cd discord-bot
npm install
```

2. **Configure environment:**
```bash
cp .env.example .env
```

Edit `.env` with your values:
```env
DISCORD_TOKEN=your_bot_token
DISCORD_CLIENT_ID=your_client_id
DISCORD_GUILD_ID=your_guild_id
GITHUB_TOKEN=your_github_token
GITHUB_REPOSITORY=owner/repo
TICKET_CATEGORY_ID=discord_category_id
```

3. **Register commands:**
```bash
node src/utils/deploy-commands.js
```

4. **Start bot:**
```bash
npm start
```

### GitHub Actions Setup

1. **Add repository secrets:**
   - `DISCORD_WEBHOOK_URL`: Discord webhook for posting results

2. **Verify workflows:**
```bash
# Check workflow files exist
ls .github/workflows/

# Validate syntax
gh workflow list
```

3. **Test workflow dispatch:**
```bash
gh workflow run mod-analysis.yml \
  -f file_url="https://example.com/mod.zip" \
  -f file_name="test-mod.zip" \
  -f ticket_id="123456" \
  -f user_id="789012"
```

## Usage Examples

### Basic Mod Analysis via Discord

1. User runs `/analyze-mod` in Discord
2. Bot creates private ticket channel
3. User uploads mod.zip
4. Bot validates and triggers `mod-analysis.yml` workflow
5. GitHub Actions:
   - Downloads and extracts mod
   - Validates structure
   - Checks info.json
   - Analyzes Lua files
   - Generates report
6. Results posted to Discord ticket
7. User reviews and closes ticket with `/close-ticket`

### Cross-Repository Workflow

```javascript
// In repository A, trigger workflow in repository B
const { Octokit } = require('@octokit/rest');
const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN });

await octokit.actions.createWorkflowDispatch({
  owner: 'org',
  repo: 'factorify-workflows',
  workflow_id: 'cross-repo-orchestration.yml',
  ref: 'main',
  inputs: {
    mod_path: './my-mod',
    run_validation: 'true',
    run_security: 'true',
    run_benchmark: 'false'
  }
});
```

### Using Reusable Workflows

```yaml
# In your repository's workflow
name: My Mod CI

on: [push, pull_request]

jobs:
  validate:
    uses: org/factorify-workflows/.github/workflows/reusable-mod-validation.yml@v1
    with:
      mod_path: './my-mod'
      validation_level: 'strict'

  security:
    uses: org/factorify-workflows/.github/workflows/reusable-security-scan.yml@v1
    with:
      mod_path: './my-mod'
      scan_depth: 'deep'
```

## Authentication Configuration

### Default: No Authentication
```javascript
// discord-bot/src/config/index.js
authentication: {
  enabled: false  // Default
}
```

GitHub Actions use automatic `GITHUB_TOKEN`:
```yaml
steps:
  - uses: actions/checkout@v4
  # Token available automatically as ${{ secrets.GITHUB_TOKEN }}
```

### Optional: Enable GitHub App Auth
```javascript
// discord-bot/src/config/index.js
authentication: {
  enabled: true,
  githubAppId: process.env.GITHUB_APP_ID,
  githubAppPrivateKey: process.env.GITHUB_APP_PRIVATE_KEY
}
```

```bash
# .env
AUTH_ENABLED=true
GITHUB_APP_ID=123456
GITHUB_APP_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n..."
```

## Testing

### Test Discord Bot Locally
```bash
cd discord-bot
npm start

# In Discord:
# 1. /analyze-mod
# 2. Upload test file
# 3. Verify workflow triggered
```

### Test Workflow Directly
```bash
# Trigger mod analysis
gh workflow run mod-analysis.yml \
  -f file_url="https://raw.githubusercontent.com/owner/repo/main/test-mod.zip" \
  -f file_name="test.zip" \
  -f ticket_id="test" \
  -f user_id="test"

# Check status
gh run list --workflow=mod-analysis.yml

# View logs
gh run view --log
```

### Test Reusable Workflows
```bash
# Trigger orchestration workflow
gh workflow run cross-repo-orchestration.yml \
  -f mod_path="./test-mod" \
  -f run_validation=true \
  -f run_security=true \
  -f run_benchmark=true
```

## Migration from Phase 10

### Step 1: Deprecate External APIs
The REST/GraphQL APIs in `/factorify-migration/cross_repo_api/` are kept for reference but not actively used. GitHub Actions workflows replace these endpoints.

**Mapping:**
- `POST /api/validate` → Trigger `reusable-mod-validation.yml`
- `POST /api/security` → Trigger `reusable-security-scan.yml`
- `POST /api/benchmark` → Trigger `reusable-performance-benchmark.yml`

### Step 2: Update Client Code
Replace API calls with workflow dispatch:

**Before:**
```javascript
const response = await fetch('https://api.factorify.dev/validate', {
  method: 'POST',
  body: JSON.stringify({ modPath: './mod' })
});
```

**After:**
```javascript
await octokit.actions.createWorkflowDispatch({
  owner: 'org',
  repo: 'factorify',
  workflow_id: 'reusable-mod-validation.yml',
  ref: 'main',
  inputs: { mod_path: './mod' }
});
```

### Step 3: Configure Authentication
Authentication is now optional (default: off):

```javascript
const { OptionalAuth } = require('./authentication/optional_auth');
const auth = new OptionalAuth({
  enabled: false  // No auth for internal use
});
```

Enable only if external API access needed:
```javascript
const auth = new OptionalAuth({
  enabled: true,
  githubAppConfig: { /* ... */ }
});
```

## Advantages

### Cost Savings
- ❌ No server hosting fees
- ❌ No database costs
- ❌ No CDN/load balancer
- ✅ Free GitHub Actions (public repos)
- ✅ Free artifact storage (limited)

### Reduced Complexity
- ❌ No server maintenance
- ❌ No database backups
- ❌ No SSL certificates
- ✅ GitHub-managed infrastructure
- ✅ Built-in monitoring

### Better Integration
- ✅ Native GitHub integration
- ✅ Built-in secrets management
- ✅ Audit logs included
- ✅ Automatic retries
- ✅ Status badges

## Limitations

### GitHub Actions Constraints
- 6 hour timeout per workflow
- Limited to GitHub-hosted runners (unless self-hosted)
- Rate limits on API calls
- Artifact retention limits

### Discord Bot Constraints
- 25MB file upload limit (configurable)
- Rate limits on Discord API
- Requires bot to be online

## Troubleshooting

### Discord Bot Not Responding
1. Check token validity
2. Verify bot permissions
3. Check console logs
4. Ensure commands are registered

### Workflow Not Triggering
1. Verify `GITHUB_TOKEN` has `actions:write` scope
2. Check workflow file exists
3. Verify repository format: `owner/repo`
4. Check GitHub Actions logs

### Results Not Posted to Discord
1. Verify `DISCORD_WEBHOOK_URL` secret
2. Check webhook permissions
3. Review GitHub Actions logs
4. Test webhook manually

## Future Enhancements

### Planned Features
- [ ] Multi-file batch uploads
- [ ] Real-time progress updates via Discord
- [ ] Custom validation rules per user
- [ ] Workflow result caching
- [ ] Advanced pattern detection
- [ ] Dependency graph analysis
- [ ] Automated fix suggestions

### Potential Repository Migration
While this implementation keeps code in `factory-levels-forked`, a future phase could:
1. Create separate `factorify` repository
2. Migrate workflows and Discord bot
3. Preserve git history
4. Set up cross-repo triggers

## Conclusion

Phase 11 successfully implements:
- ✅ GitHub Actions-native architecture
- ✅ Discord bot with ticket system
- ✅ Optional authentication (default: off)
- ✅ Reusable workflow patterns
- ✅ Complete documentation
- ✅ Zero external server costs

The system is production-ready for internal use and can be extended for external API access by enabling authentication.

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Discord.js Guide](https://discordjs.guide/)
- [Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [Workflow Dispatch](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_dispatch)
