# Factory Levels - Factorio Mod

## ⚠️ Important Notice: API Migration to Factorify

**API development has been migrated to [Symgot/Factorify](https://github.com/Symgot/Factorify)**

This repository now focuses on:
- Original Factorio mod source code (`factory-levels/`)
- Comprehensive test suite (117 tests in `tests/`)
- Historical phase completion documentation
- Integration testing with Factorify

For advanced mod analysis features including:
- ML-based pattern recognition
- Performance optimization
- Obfuscation detection
- Discord bot integration
- GitHub Actions workflows

Please visit: **https://github.com/Symgot/Factorify**

---

## Phase 11 Completion Status

### ✅ GitHub Actions Native Integration
- Direct workflow_dispatch integration (no external servers)
- Self-contained workflow templates
- Optional GitHub App authentication
- Zero infrastructure costs

### ✅ Discord Bot Implementation
- File upload support (.lua, .zip, .tar.gz)
- Private ticket system per user
- Real-time analysis updates
- Detailed error reporting with fix suggestions

### ✅ Repository Migration
- Migration guide: [FACTORIFY_MIGRATION.md](./FACTORIFY_MIGRATION.md)
- ~35,000+ lines migrated to Factorify
- Full Git history preservation
- Tests retained in this repository

---

## What's in This Repository

### Tests (`tests/`)
117 comprehensive Lua test files for validation:
- API reference checking
- Bytecode analysis
- Complete decompilation tests
- Parser validation
- Mock Factorio environment

### Factory Levels Mod (`factory-levels/`)
Original Factorio mod source code with level-based factory management.

### Phase Documentation
Complete documentation of all development phases (1-11):
- `PHASE*_COMPLETION.md` - Detailed phase summaries
- `IMPLEMENTATION_SUMMARY.md` - Technical specifications
- `FACTORIFY_MIGRATION.md` - Migration instructions

---

## Integration with Factorify

### Running Tests with Factorify

Tests in this repository can be run standalone or integrated with Factorify analysis:

```bash
# Run local tests
cd tests
lua test_runner.lua

# Run with Factorify integration (after migration)
# See .github/workflows/test-with-factorify.yml
```

### Using the Discord Bot

Upload mods for analysis via Discord:

```
/analyze file:your-mod.zip
```

The bot will:
1. Create a private ticket channel
2. Extract and validate files
3. Trigger GitHub Actions workflow
4. Post detailed results with error reports

---

## Development History

This repository evolved through 11 major phases:

1. **Phase 1-4**: Core mod development
2. **Phase 5**: ML Pattern Recognition (~2,100 lines)
3. **Phase 6**: Enterprise Monitoring (~850 lines)
4. **Phase 7**: LSP Server Integration (~370 lines)
5. **Phase 8**: AI Assistant Integration (~929 lines)
6. **Phase 9**: Documentation System (~2,000 lines)
7. **Phase 10**: Cross-Repository Orchestration (~12,500 lines)
8. **Phase 11**: GitHub Actions Native + Discord Bot (~7,500 lines)

**Total Code Generated**: ~47,000+ lines across all phases

---

## License

MIT License - See [LICENSE](./LICENSE) file

---

## Links

- **Factorify Repository**: https://github.com/Symgot/Factorify
- **Original Mod** (Archived): https://codeberg.org/renoth/factorio-factory-levels
- **Phase 11 Issue**: [#44](https://github.com/Symgot/factory-levels-forked/issues/44)

---

## Contributing

For mod analysis features, contribute to [Factorify](https://github.com/Symgot/Factorify).

For test improvements or mod code, open issues/PRs in this repository.
