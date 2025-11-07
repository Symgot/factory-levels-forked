const { Octokit } = require('@octokit/rest');

/**
 * RunnerCoordinator - GitHub-hosted runner management
 * Coordinates execution across GitHub Actions runners without external server
 */
class RunnerCoordinator {
  constructor(token, owner, repo) {
    this.octokit = new Octokit({ auth: token });
    this.owner = owner;
    this.repo = repo;
  }

  /**
   * Get list of available runners for the repository
   * @returns {Promise<object>} - List of runners
   */
  async listRunners() {
    try {
      const response = await this.octokit.rest.actions.listSelfHostedRunnersForRepo({
        owner: this.owner,
        repo: this.repo
      });

      return {
        success: true,
        total_count: response.data.total_count,
        runners: response.data.runners.map(runner => ({
          id: runner.id,
          name: runner.name,
          os: runner.os,
          status: runner.status,
          busy: runner.busy,
          labels: runner.labels.map(l => l.name)
        }))
      };
    } catch (error) {
      console.error(`[RunnerCoordinator] Error listing runners: ${error.message}`);
      return {
        success: true,
        total_count: 0,
        runners: [],
        note: 'Using GitHub-hosted runners (no self-hosted runners available)'
      };
    }
  }

  /**
   * Get jobs for a specific workflow run
   * @param {number} runId - Workflow run ID
   * @returns {Promise<object>} - List of jobs
   */
  async listWorkflowRunJobs(runId) {
    try {
      const response = await this.octokit.rest.actions.listJobsForWorkflowRun({
        owner: this.owner,
        repo: this.repo,
        run_id: runId
      });

      return {
        success: true,
        total_count: response.data.total_count,
        jobs: response.data.jobs.map(job => ({
          id: job.id,
          run_id: job.run_id,
          name: job.name,
          status: job.status,
          conclusion: job.conclusion,
          started_at: job.started_at,
          completed_at: job.completed_at,
          runner_name: job.runner_name,
          runner_group_name: job.runner_group_name,
          steps: job.steps ? job.steps.map(step => ({
            name: step.name,
            status: step.status,
            conclusion: step.conclusion,
            number: step.number
          })) : []
        }))
      };
    } catch (error) {
      console.error(`[RunnerCoordinator] Error listing jobs: ${error.message}`);
      throw new Error(`Failed to list jobs for run ${runId}: ${error.message}`);
    }
  }

  /**
   * Get job by ID
   * @param {number} jobId - Job ID
   * @returns {Promise<object>} - Job details
   */
  async getJob(jobId) {
    try {
      const response = await this.octokit.rest.actions.getJobForWorkflowRun({
        owner: this.owner,
        repo: this.repo,
        job_id: jobId
      });

      return {
        success: true,
        id: response.data.id,
        run_id: response.data.run_id,
        name: response.data.name,
        status: response.data.status,
        conclusion: response.data.conclusion,
        started_at: response.data.started_at,
        completed_at: response.data.completed_at,
        html_url: response.data.html_url,
        runner_name: response.data.runner_name,
        runner_group_name: response.data.runner_group_name,
        steps: response.data.steps ? response.data.steps.map(step => ({
          name: step.name,
          status: step.status,
          conclusion: step.conclusion,
          number: step.number,
          started_at: step.started_at,
          completed_at: step.completed_at
        })) : []
      };
    } catch (error) {
      console.error(`[RunnerCoordinator] Error getting job: ${error.message}`);
      throw new Error(`Failed to get job ${jobId}: ${error.message}`);
    }
  }

  /**
   * Get job logs
   * @param {number} jobId - Job ID
   * @returns {Promise<string>} - Job logs as text
   */
  async downloadJobLogs(jobId) {
    try {
      const response = await this.octokit.rest.actions.downloadJobLogsForWorkflowRun({
        owner: this.owner,
        repo: this.repo,
        job_id: jobId
      });

      return {
        success: true,
        jobId: jobId,
        logs: response.data
      };
    } catch (error) {
      console.error(`[RunnerCoordinator] Error downloading job logs: ${error.message}`);
      throw new Error(`Failed to download logs for job ${jobId}: ${error.message}`);
    }
  }

  /**
   * Coordinate matrix strategy execution
   * Creates configuration for GitHub Actions matrix strategy
   * @param {object} matrixConfig - Matrix configuration
   * @returns {object} - Matrix strategy for workflow
   */
  createMatrixStrategy(matrixConfig) {
    const {
      os = ['ubuntu-latest'],
      nodeVersion = ['18', '20'],
      parallelism = 4,
      failFast = false
    } = matrixConfig;

    return {
      strategy: {
        matrix: {
          os: os,
          'node-version': nodeVersion
        },
        'fail-fast': failFast,
        'max-parallel': parallelism
      }
    };
  }

  /**
   * Monitor job execution progress
   * @param {number} runId - Workflow run ID
   * @param {number} pollInterval - Polling interval in milliseconds
   * @param {number} timeout - Maximum wait time in milliseconds
   * @returns {Promise<object>} - Final job status
   */
  async monitorJobExecution(runId, pollInterval = 5000, timeout = 600000) {
    const startTime = Date.now();
    
    while (Date.now() - startTime < timeout) {
      try {
        const jobs = await this.listWorkflowRunJobs(runId);
        
        const allCompleted = jobs.jobs.every(job => 
          job.status === 'completed'
        );

        if (allCompleted) {
          const allSuccessful = jobs.jobs.every(job => 
            job.conclusion === 'success'
          );

          return {
            success: true,
            completed: true,
            allSuccessful: allSuccessful,
            jobs: jobs.jobs,
            duration: Date.now() - startTime
          };
        }

        await new Promise(resolve => setTimeout(resolve, pollInterval));
      } catch (error) {
        console.error(`[RunnerCoordinator] Error monitoring job: ${error.message}`);
      }
    }

    return {
      success: false,
      completed: false,
      error: 'Timeout waiting for job completion',
      duration: Date.now() - startTime
    };
  }

  /**
   * Get runner usage statistics for the repository
   * @param {number} perPage - Results per page
   * @returns {Promise<object>} - Usage statistics
   */
  async getRunnerUsageStats(perPage = 30) {
    try {
      const response = await this.octokit.rest.actions.listWorkflowRunsForRepo({
        owner: this.owner,
        repo: this.repo,
        per_page: perPage
      });

      const runs = response.data.workflow_runs;
      const stats = {
        total_runs: runs.length,
        completed: runs.filter(r => r.status === 'completed').length,
        in_progress: runs.filter(r => r.status === 'in_progress').length,
        queued: runs.filter(r => r.status === 'queued').length,
        successful: runs.filter(r => r.conclusion === 'success').length,
        failed: runs.filter(r => r.conclusion === 'failure').length,
        cancelled: runs.filter(r => r.conclusion === 'cancelled').length
      };

      return {
        success: true,
        period: 'recent',
        stats: stats,
        runs: runs.map(run => ({
          id: run.id,
          name: run.name,
          status: run.status,
          conclusion: run.conclusion,
          created_at: run.created_at,
          updated_at: run.updated_at
        }))
      };
    } catch (error) {
      console.error(`[RunnerCoordinator] Error getting usage stats: ${error.message}`);
      throw new Error(`Failed to get runner usage stats: ${error.message}`);
    }
  }

  /**
   * Re-run a failed workflow run
   * @param {number} runId - Workflow run ID to re-run
   * @returns {Promise<object>} - Re-run result
   */
  async rerunWorkflowRun(runId) {
    try {
      await this.octokit.rest.actions.reRunWorkflow({
        owner: this.owner,
        repo: this.repo,
        run_id: runId
      });

      console.log(`[RunnerCoordinator] Re-running workflow run ${runId}`);
      return {
        success: true,
        runId: runId,
        message: 'Workflow run re-queued successfully'
      };
    } catch (error) {
      console.error(`[RunnerCoordinator] Error re-running workflow: ${error.message}`);
      throw new Error(`Failed to re-run workflow ${runId}: ${error.message}`);
    }
  }

  /**
   * Re-run only failed jobs in a workflow run
   * @param {number} runId - Workflow run ID
   * @returns {Promise<object>} - Re-run result
   */
  async rerunFailedJobs(runId) {
    try {
      await this.octokit.rest.actions.reRunWorkflowFailedJobs({
        owner: this.owner,
        repo: this.repo,
        run_id: runId
      });

      console.log(`[RunnerCoordinator] Re-running failed jobs for run ${runId}`);
      return {
        success: true,
        runId: runId,
        message: 'Failed jobs re-queued successfully'
      };
    } catch (error) {
      console.error(`[RunnerCoordinator] Error re-running failed jobs: ${error.message}`);
      throw new Error(`Failed to re-run failed jobs for ${runId}: ${error.message}`);
    }
  }
}

module.exports = RunnerCoordinator;
