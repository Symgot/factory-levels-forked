#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

console.log('🔍 Phase 11 Validation Script\n');

const checks = {
  passed: 0,
  failed: 0,
  warnings: 0
};

function checkFile(filePath, description) {
  if (fs.existsSync(filePath)) {
    console.log(`✅ ${description}`);
    checks.passed++;
    return true;
  } else {
    console.log(`❌ ${description} - MISSING: ${filePath}`);
    checks.failed++;
    return false;
  }
}

function checkDirectory(dirPath, description) {
  if (fs.existsSync(dirPath) && fs.statSync(dirPath).isDirectory()) {
    const files = fs.readdirSync(dirPath);
    console.log(`✅ ${description} (${files.length} files)`);
    checks.passed++;
    return true;
  } else {
    console.log(`❌ ${description} - MISSING: ${dirPath}`);
    checks.failed++;
    return false;
  }
}

function checkFileContent(filePath, searchString, description) {
  if (fs.existsSync(filePath)) {
    const content = fs.readFileSync(filePath, 'utf8');
    if (content.includes(searchString)) {
      console.log(`✅ ${description}`);
      checks.passed++;
      return true;
    } else {
      console.log(`⚠️  ${description} - Pattern not found: ${searchString}`);
      checks.warnings++;
      return false;
    }
  } else {
    console.log(`❌ ${description} - File missing: ${filePath}`);
    checks.failed++;
    return false;
  }
}

console.log('📦 Phase 11.1: GitHub Actions Native Integration\n');

checkDirectory('github_actions_integration', 'GitHub Actions Integration directory');
checkFile('github_actions_integration/workflow_dispatcher.js', 'WorkflowDispatcher implementation');
checkFile('github_actions_integration/runner_coordinator.js', 'RunnerCoordinator implementation');
checkFile('github_actions_integration/status_tracker.js', 'StatusTracker implementation');
checkFile('github_actions_integration/package.json', 'GitHub Actions Integration package.json');
checkFile('github_actions_integration/README.md', 'GitHub Actions Integration documentation');

checkFileContent(
  'github_actions_integration/workflow_dispatcher.js',
  'workflow_dispatch',
  'Direct workflow_dispatch implementation'
);

console.log('\n🤖 Phase 11.2: Discord Bot Implementation\n');

checkDirectory('discord_bot', 'Discord Bot directory');
checkFile('discord_bot/bot.js', 'Main bot logic');
checkFile('discord_bot/package.json', 'Discord Bot package.json');
checkFile('discord_bot/README.md', 'Discord Bot documentation');
checkFile('discord_bot/deploy-commands.js', 'Command deployment script');

checkDirectory('discord_bot/commands', 'Discord commands');
checkFile('discord_bot/commands/analyze.js', 'Analyze command');
checkFile('discord_bot/commands/status.js', 'Status command');
checkFile('discord_bot/commands/help.js', 'Help command');
checkFile('discord_bot/commands/config.js', 'Config command');

checkDirectory('discord_bot/ticket_system', 'Ticket system');
checkFile('discord_bot/ticket_system/ticket_manager.js', 'Ticket manager');

checkDirectory('discord_bot/file_handler', 'File handler');
checkFile('discord_bot/file_handler/upload_handler.js', 'Upload handler');

checkDirectory('discord_bot/github_integration', 'GitHub integration');
checkFile('discord_bot/github_integration/workflow_trigger.js', 'Workflow trigger');
checkFile('discord_bot/github_integration/result_parser.js', 'Result parser');

checkDirectory('discord_bot/error_reporter', 'Error reporter');
checkFile('discord_bot/error_reporter/detailed_formatter.js', 'Detailed formatter');
checkFile('discord_bot/error_reporter/embed_generator.js', 'Embed generator');

console.log('\n🔐 Optional Authentication\n');

checkDirectory('authentication', 'Authentication directory');
checkFile('authentication/github_app.js', 'GitHub App authentication');
checkFileContent(
  'authentication/github_app.js',
  'ENABLE_GITHUB_APP_AUTH',
  'Optional authentication feature flag'
);

console.log('\n📚 Phase 11.3: Migration Documentation\n');

checkFile('FACTORIFY_MIGRATION.md', 'Migration guide');
checkFileContent(
  'FACTORIFY_MIGRATION.md',
  'git-filter-repo',
  'Git filter-repo instructions'
);

console.log('\n⚙️  Phase 11.4: Repository Updates\n');

checkFile('.github/workflows/test-with-factorify.yml', 'Factorify integration workflow');
checkFile('README.md', 'Updated README');
checkFile('package.json', 'Root package.json');

checkFileContent(
  'README.md',
  'Symgot/Factorify',
  'Factorify migration notice in README'
);

console.log('\n🧪 Tests and Structure\n');

checkDirectory('tests', 'Tests directory');
const testFiles = fs.readdirSync('tests').filter(f => f.endsWith('.lua'));
console.log(`ℹ️  Found ${testFiles.length} Lua test files`);
if (testFiles.length >= 30) {
  console.log(`✅ Sufficient test coverage (${testFiles.length} files)`);
  checks.passed++;
} else {
  console.log(`⚠️  Low test coverage (${testFiles.length} files)`);
  checks.warnings++;
}

console.log('\n📊 Validation Summary\n');
console.log(`✅ Passed: ${checks.passed}`);
console.log(`❌ Failed: ${checks.failed}`);
console.log(`⚠️  Warnings: ${checks.warnings}`);

const total = checks.passed + checks.failed + checks.warnings;
const passRate = ((checks.passed / total) * 100).toFixed(1);

console.log(`\n📈 Pass Rate: ${passRate}%`);

if (checks.failed > 0) {
  console.log('\n❌ Validation FAILED - Missing required components');
  process.exit(1);
} else if (checks.warnings > 0) {
  console.log('\n⚠️  Validation PASSED with warnings');
  process.exit(0);
} else {
  console.log('\n✅ Validation PASSED - All Phase 11 components present');
  process.exit(0);
}
