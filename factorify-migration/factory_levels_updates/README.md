# Factory Levels - Factorio Mod

**Status**: Mod code archived - See https://codeberg.org/renoth/factorio-factory-levels

## Factorify API Integration

This repository now serves as a test and validation suite for the **Factorify** API platform.

### What is Factorify?

Factorify is an enterprise-grade API platform for Factorio mod analysis, providing:

- 🤖 **ML Pattern Recognition**: AI-powered code analysis
- ⚡ **Performance Optimization**: Sub-20ms parse times
- 🔒 **Security Scanning**: Obfuscation detection
- 🌐 **Cross-Repository Integration**: REST + GraphQL APIs
- 📊 **Distributed Orchestration**: Multi-repo workflows

### Quick Links

- **Factorify Repository**: https://github.com/Symgot/Factorify
- **API Documentation**: https://github.com/Symgot/Factorify/wiki/API-Reference
- **Migration Guide**: [PHASE10_MIGRATION_GUIDE.md](PHASE10_MIGRATION_GUIDE.md)
- **Workflow Templates**: https://github.com/Symgot/Factorify/tree/main/.github/workflow-templates

## Test Suite

This repository maintains 30 comprehensive Lua test files for validating Factorify API functionality:

```
tests/
├── test_control.lua                    # Control stage tests
├── test_defines_complete.lua           # Defines API coverage
├── test_event_system.lua               # Event handling tests
├── test_runtime_classes.lua            # Runtime API tests
├── test_prototype_classes_extended.lua # Prototype tests
└── ... (25 more test files)
```

## Running Tests

### Local Testing

```bash
lua tests/test_control.lua
```

### With Factorify API

```bash
# Set your API token
export FACTORIFY_API_TOKEN="your-token-here"

# Run GitHub Actions workflow
gh workflow run factorify-integration.yml
```

## Using Factorify in Your Mod

### 1. Add GitHub Actions Workflow

Create `.github/workflows/factorify.yml`:

```yaml
name: Mod Validation

on: [push, pull_request]

jobs:
  validate:
    uses: Symgot/Factorify/.github/workflows/factorify-mod-validation.yml@v1
    secrets:
      FACTORIFY_API_TOKEN: ${{ secrets.FACTORIFY_API_TOKEN }}
```

### 2. Configure API Token

```bash
gh secret set FACTORIFY_API_TOKEN --body "your-token-here"
```

### 3. Analyze Your Mod

```bash
curl -X POST https://api.factorify.dev/api/v1/analyze/mod \
  -H "Authorization: Bearer $FACTORIFY_API_TOKEN" \
  -d '{"repository":"user/my-mod","type":"full"}'
```

## API Examples

### REST API

```bash
# Submit analysis
curl -X POST https://api.factorify.dev/api/v1/analyze/mod \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"repository":"user/mod"}'

# Check status
curl https://api.factorify.dev/api/v1/status/JOB_ID \
  -H "Authorization: Bearer $TOKEN"
```

### GraphQL API

```graphql
query {
  analyzeModFile(url: "https://github.com/user/mod/blob/main/control.lua") {
    ml { class confidence }
    performance { parseTime }
    obfuscation { score }
    quality
  }
}
```

## Migration from API-Integration Branch

The API integration code has been migrated to the dedicated Factorify repository. See [PHASE10_MIGRATION_GUIDE.md](PHASE10_MIGRATION_GUIDE.md) for:

- Complete migration steps
- Git history preservation
- Repository cleanup
- API endpoint updates

## Performance Metrics

| Metric | Target | Status |
|--------|--------|--------|
| Test Coverage | 30 files | ✅ |
| API Response | <5s | ✅ |
| Parse Time | <20ms | ✅ |
| ML Inference | <50ms | ✅ |

## Contributing

Contributions to the test suite are welcome! Please:

1. Fork the repository
2. Add/improve test cases
3. Ensure all tests pass locally
4. Submit a pull request

## Support

- **Issues**: https://github.com/Symgot/factory-levels-forked/issues
- **Factorify Issues**: https://github.com/Symgot/Factorify/issues
- **Documentation**: https://github.com/Symgot/Factorify/wiki

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Original mod code: https://codeberg.org/renoth/factorio-factory-levels
- Factorio API documentation: https://lua-api.factorio.com/
- Community contributors and testers

---

**Phase 10 Status**: ✅ API Migration Complete  
**Factorify Version**: v1.0.0  
**Last Updated**: 2024-11-07
