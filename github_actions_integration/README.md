# GitHub Actions Native Integration

100% GitHub-native integration without external servers. All functionality runs on GitHub-hosted runners using direct `workflow_dispatch` API calls.

## Features

- **Zero External Dependencies**: No separate API servers required
- **Direct Workflow Dispatch**: Trigger workflows using GitHub REST API
- **Runner Coordination**: Manage GitHub-hosted runners with matrix strategies
- **Status Tracking**: Real-time job status polling via GitHub API
- **Artifact Management**: Download and manage workflow artifacts
- **Optional Authentication**: Works with or without GitHub App credentials

## Modules

### WorkflowDispatcher
Direct GitHub Actions workflow_dispatch integration.

```javascript
const { WorkflowDispatcher } = require('./github_actions_integration');

const dispatcher = new WorkflowDispatcher(token, 'owner', 'repo');

// Trigger a workflow
await dispatcher.triggerWorkflow('standalone_validation.yml', {
  mod_files: base64EncodedFiles,
  ticket_id: 'ticket-123'
});

// Get workflow status
const status = await dispatcher.getWorkflowStatus(runId);

// Download artifacts
const artifacts = await dispatcher.listWorkflowRunArtifacts(runId);
```

### RunnerCoordinator
GitHub-hosted runner management and job coordination.

```javascript
const { RunnerCoordinator } = require('./github_actions_integration');

const coordinator = new RunnerCoordinator(token, 'owner', 'repo');

// List jobs for a run
const jobs = await coordinator.listWorkflowRunJobs(runId);

// Monitor job execution
const result = await coordinator.monitorJobExecution(runId, 5000, 600000);

// Create matrix strategy
const matrix = coordinator.createMatrixStrategy({
  os: ['ubuntu-latest', 'windows-latest'],
  nodeVersion: ['18', '20'],
  parallelism: 4
});
```

### StatusTracker
Real-time job status polling and tracking.

```javascript
const { StatusTracker } = require('./github_actions_integration');

const tracker = new StatusTracker(token, 'owner', 'repo');

// Track workflow with callbacks
await tracker.trackWorkflowRun(runId, {
  onStatusChange: (status) => console.log('Status:', status.status),
  onJobComplete: (job) => console.log('Job done:', job.jobName),
  onComplete: (status) => console.log('Workflow complete:', status.conclusion)
});

// Wait for completion
const result = await tracker.waitForCompletion(runId, 600000);

// Get conclusion summary
const summary = await tracker.getConclusionSummary(runId);
```

## Usage Examples

### Basic Workflow Trigger

```javascript
const { WorkflowDispatcher, StatusTracker } = require('./github_actions_integration');

async function analyzeModFile(fileContent) {
  const dispatcher = new WorkflowDispatcher(
    process.env.GITHUB_TOKEN,
    'Symgot',
    'Factorify'
  );
  
  // Trigger validation workflow
  const trigger = await dispatcher.triggerWorkflow(
    'standalone_validation.yml',
    { mod_files: Buffer.from(fileContent).toString('base64') }
  );
  
  // Wait for latest run
  await new Promise(resolve => setTimeout(resolve, 2000));
  const latestRun = await dispatcher.getLatestWorkflowRun('standalone_validation.yml');
  
  // Track execution
  const tracker = new StatusTracker(
    process.env.GITHUB_TOKEN,
    'Symgot',
    'Factorify'
  );
  
  const result = await tracker.waitForCompletion(latestRun.id);
  
  // Download artifacts
  if (result.completed) {
    const artifacts = await dispatcher.listWorkflowRunArtifacts(latestRun.id);
    console.log('Analysis complete. Artifacts:', artifacts);
  }
}
```

### Matrix Strategy Execution

```javascript
const { RunnerCoordinator } = require('./github_actions_integration');

async function runParallelTests(runId) {
  const coordinator = new RunnerCoordinator(
    process.env.GITHUB_TOKEN,
    'Symgot',
    'Factorify'
  );
  
  // Monitor parallel job execution
  const result = await coordinator.monitorJobExecution(runId, 3000, 600000);
  
  if (result.completed) {
    console.log(`All jobs completed. Success: ${result.allSuccessful}`);
    
    // Get detailed stats
    const stats = await coordinator.getRunnerUsageStats();
    console.log('Runner stats:', stats);
  }
}
```

## Environment Variables

- `GITHUB_TOKEN`: GitHub personal access token or App installation token
- `ENABLE_GITHUB_APP_AUTH`: Optional flag to enable GitHub App authentication (default: false)

## API Reference

### WorkflowDispatcher

#### Methods

- `triggerWorkflow(workflowId, inputs, ref)` - Trigger a workflow
- `listWorkflowRuns(workflowId, options)` - List workflow runs
- `getLatestWorkflowRun(workflowId, branch)` - Get latest run
- `getWorkflowRun(runId)` - Get run details
- `cancelWorkflowRun(runId)` - Cancel a run
- `downloadArtifact(artifactId)` - Download artifact
- `listWorkflowRunArtifacts(runId)` - List artifacts

### RunnerCoordinator

#### Methods

- `listRunners()` - List available runners
- `listWorkflowRunJobs(runId)` - List jobs for run
- `getJob(jobId)` - Get job details
- `downloadJobLogs(jobId)` - Download job logs
- `createMatrixStrategy(config)` - Create matrix configuration
- `monitorJobExecution(runId, interval, timeout)` - Monitor execution
- `getRunnerUsageStats(perPage)` - Get usage statistics
- `rerunWorkflowRun(runId)` - Re-run workflow
- `rerunFailedJobs(runId)` - Re-run failed jobs only

### StatusTracker

#### Methods

- `getWorkflowStatus(runId)` - Get workflow status
- `trackWorkflowRun(runId, callbacks, interval)` - Track with callbacks
- `stopTracking(runId)` - Stop tracking run
- `stopAllTracking()` - Stop all tracking
- `getJobStatus(jobId)` - Get detailed job status
- `getWorkflowTiming(runId)` - Get timing information
- `isWorkflowInProgress(runId)` - Check if in progress
- `waitForCompletion(runId, timeout, interval)` - Wait for completion
- `getConclusionSummary(runId)` - Get conclusion summary

## Architecture

```
GitHub Actions Native Integration
│
├── WorkflowDispatcher
│   ├── Direct workflow_dispatch API calls
│   ├── Workflow run management
│   └── Artifact download
│
├── RunnerCoordinator
│   ├── GitHub-hosted runner coordination
│   ├── Job execution monitoring
│   └── Matrix strategy management
│
└── StatusTracker
    ├── Real-time status polling
    ├── Job progress tracking
    └── Completion detection
```

## Cost Efficiency

- **Zero Infrastructure Costs**: Uses GitHub Free Tier
- **No External Servers**: All logic runs on GitHub Actions
- **Efficient Polling**: Configurable intervals to minimize API calls
- **Matrix Parallelism**: Faster execution with concurrent jobs

## Comparison: External API vs GitHub Native

### Before (Phase 10 - External API)
```
Discord Bot → Factorify API Server → GitHub Actions
              ↓
         PostgreSQL Database
              ↓
         Authentication Layer
```
**Costs**: Server hosting, database, monitoring

### After (Phase 11 - GitHub Native)
```
Discord Bot → GitHub API (workflow_dispatch) → GitHub Actions
```
**Costs**: $0 (GitHub Free Tier)

## Security

- Uses GitHub Personal Access Tokens or App Installation Tokens
- No credentials stored externally
- Optional GitHub App authentication
- Rate limiting protection built-in

## Performance

- Direct API calls: <500ms latency
- Status polling: Configurable intervals (default: 3-5s)
- Artifact download: Streamed directly from GitHub
- Parallel execution: Matrix strategy with up to 20 concurrent jobs

## License

MIT
