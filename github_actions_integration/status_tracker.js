const { Octokit } = require('@octokit/rest');

/**
 * StatusTracker - GitHub Actions job status polling
 * Tracks workflow execution status without external server
 */
class StatusTracker {
  constructor(token, owner, repo) {
    this.octokit = new Octokit({ auth: token });
    this.owner = owner;
    this.repo = repo;
    this.activeTrackers = new Map();
  }

  /**
   * Get workflow run status
   * @param {number} runId - Workflow run ID
   * @returns {Promise<object>} - Status information
   */
  async getWorkflowStatus(runId) {
    try {
      const response = await this.octokit.rest.actions.getWorkflowRun({
        owner: this.owner,
        repo: this.repo,
        run_id: runId
      });

      return {
        success: true,
        runId: runId,
        status: response.data.status,
        conclusion: response.data.conclusion,
        created_at: response.data.created_at,
        updated_at: response.data.updated_at,
        run_started_at: response.data.run_started_at,
        html_url: response.data.html_url,
        workflow_name: response.data.name,
        event: response.data.event,
        head_branch: response.data.head_branch,
        head_sha: response.data.head_sha
      };
    } catch (error) {
      console.error(`[StatusTracker] Error getting workflow status: ${error.message}`);
      throw new Error(`Failed to get status for run ${runId}: ${error.message}`);
    }
  }

  /**
   * Track workflow run with polling
   * @param {number} runId - Workflow run ID to track
   * @param {object} callbacks - Callback functions for status updates
   * @param {number} pollInterval - Polling interval in milliseconds
   * @returns {Promise<object>} - Final status
   */
  async trackWorkflowRun(runId, callbacks = {}, pollInterval = 3000) {
    const {
      onStatusChange = null,
      onJobComplete = null,
      onComplete = null,
      onError = null
    } = callbacks;

    let lastStatus = null;
    let isTracking = true;
    
    this.activeTrackers.set(runId, { isTracking: true });

    try {
      while (isTracking && this.activeTrackers.get(runId)?.isTracking) {
        const status = await this.getWorkflowStatus(runId);

        if (status.status !== lastStatus) {
          lastStatus = status.status;
          if (onStatusChange) {
            await onStatusChange(status);
          }
        }

        if (status.status === 'completed') {
          isTracking = false;
          this.activeTrackers.delete(runId);
          
          if (onComplete) {
            await onComplete(status);
          }

          return {
            success: true,
            completed: true,
            status: status
          };
        }

        const jobs = await this.octokit.rest.actions.listJobsForWorkflowRun({
          owner: this.owner,
          repo: this.repo,
          run_id: runId
        });

        for (const job of jobs.data.jobs) {
          if (job.status === 'completed' && onJobComplete) {
            await onJobComplete({
              jobId: job.id,
              jobName: job.name,
              conclusion: job.conclusion,
              completed_at: job.completed_at
            });
          }
        }

        await new Promise(resolve => setTimeout(resolve, pollInterval));
      }

      return {
        success: false,
        completed: false,
        error: 'Tracking stopped before completion'
      };
    } catch (error) {
      console.error(`[StatusTracker] Error tracking workflow: ${error.message}`);
      this.activeTrackers.delete(runId);
      
      if (onError) {
        await onError(error);
      }

      throw error;
    }
  }

  /**
   * Stop tracking a workflow run
   * @param {number} runId - Workflow run ID to stop tracking
   */
  stopTracking(runId) {
    const tracker = this.activeTrackers.get(runId);
    if (tracker) {
      tracker.isTracking = false;
      this.activeTrackers.delete(runId);
      console.log(`[StatusTracker] Stopped tracking run ${runId}`);
    }
  }

  /**
   * Stop all active trackers
   */
  stopAllTracking() {
    for (const [runId, tracker] of this.activeTrackers.entries()) {
      tracker.isTracking = false;
    }
    this.activeTrackers.clear();
    console.log('[StatusTracker] Stopped all tracking');
  }

  /**
   * Get detailed job status with steps
   * @param {number} jobId - Job ID
   * @returns {Promise<object>} - Detailed job status
   */
  async getJobStatus(jobId) {
    try {
      const response = await this.octokit.rest.actions.getJobForWorkflowRun({
        owner: this.owner,
        repo: this.repo,
        job_id: jobId
      });

      const job = response.data;
      const steps = job.steps || [];
      
      const failedSteps = steps.filter(step => step.conclusion === 'failure');
      const successfulSteps = steps.filter(step => step.conclusion === 'success');
      
      return {
        success: true,
        jobId: jobId,
        jobName: job.name,
        status: job.status,
        conclusion: job.conclusion,
        started_at: job.started_at,
        completed_at: job.completed_at,
        duration: job.completed_at && job.started_at 
          ? new Date(job.completed_at) - new Date(job.started_at)
          : null,
        steps: {
          total: steps.length,
          successful: successfulSteps.length,
          failed: failedSteps.length,
          details: steps.map(step => ({
            name: step.name,
            status: step.status,
            conclusion: step.conclusion,
            number: step.number,
            started_at: step.started_at,
            completed_at: step.completed_at
          }))
        },
        runner_name: job.runner_name,
        runner_group_name: job.runner_group_name,
        html_url: job.html_url
      };
    } catch (error) {
      console.error(`[StatusTracker] Error getting job status: ${error.message}`);
      throw new Error(`Failed to get job status for ${jobId}: ${error.message}`);
    }
  }

  /**
   * Get workflow run timing information
   * @param {number} runId - Workflow run ID
   * @returns {Promise<object>} - Timing information
   */
  async getWorkflowTiming(runId) {
    try {
      const [runStatus, jobs] = await Promise.all([
        this.getWorkflowStatus(runId),
        this.octokit.rest.actions.listJobsForWorkflowRun({
          owner: this.owner,
          repo: this.repo,
          run_id: runId
        })
      ]);

      const jobTimings = jobs.data.jobs.map(job => {
        const duration = job.completed_at && job.started_at
          ? new Date(job.completed_at) - new Date(job.started_at)
          : null;

        return {
          jobId: job.id,
          jobName: job.name,
          started_at: job.started_at,
          completed_at: job.completed_at,
          duration_ms: duration,
          duration_formatted: duration ? `${Math.floor(duration / 1000)}s` : 'N/A'
        };
      });

      const totalDuration = runStatus.run_started_at && runStatus.updated_at
        ? new Date(runStatus.updated_at) - new Date(runStatus.run_started_at)
        : null;

      return {
        success: true,
        runId: runId,
        workflow_name: runStatus.workflow_name,
        total_duration_ms: totalDuration,
        total_duration_formatted: totalDuration ? `${Math.floor(totalDuration / 1000)}s` : 'N/A',
        started_at: runStatus.run_started_at,
        updated_at: runStatus.updated_at,
        jobs: jobTimings
      };
    } catch (error) {
      console.error(`[StatusTracker] Error getting workflow timing: ${error.message}`);
      throw new Error(`Failed to get timing for run ${runId}: ${error.message}`);
    }
  }

  /**
   * Check if workflow run is still in progress
   * @param {number} runId - Workflow run ID
   * @returns {Promise<boolean>} - True if in progress
   */
  async isWorkflowInProgress(runId) {
    try {
      const status = await this.getWorkflowStatus(runId);
      return status.status === 'in_progress' || status.status === 'queued';
    } catch (error) {
      console.error(`[StatusTracker] Error checking workflow progress: ${error.message}`);
      return false;
    }
  }

  /**
   * Wait for workflow completion with timeout
   * @param {number} runId - Workflow run ID
   * @param {number} timeout - Timeout in milliseconds
   * @param {number} pollInterval - Polling interval in milliseconds
   * @returns {Promise<object>} - Final status
   */
  async waitForCompletion(runId, timeout = 600000, pollInterval = 5000) {
    const startTime = Date.now();

    while (Date.now() - startTime < timeout) {
      const status = await this.getWorkflowStatus(runId);

      if (status.status === 'completed') {
        return {
          success: true,
          completed: true,
          status: status,
          duration: Date.now() - startTime
        };
      }

      await new Promise(resolve => setTimeout(resolve, pollInterval));
    }

    return {
      success: false,
      completed: false,
      error: 'Timeout waiting for workflow completion',
      duration: Date.now() - startTime
    };
  }

  /**
   * Get workflow run conclusion summary
   * @param {number} runId - Workflow run ID
   * @returns {Promise<object>} - Conclusion summary
   */
  async getConclusionSummary(runId) {
    try {
      const [runStatus, jobs] = await Promise.all([
        this.getWorkflowStatus(runId),
        this.octokit.rest.actions.listJobsForWorkflowRun({
          owner: this.owner,
          repo: this.repo,
          run_id: runId
        })
      ]);

      const jobConclusions = jobs.data.jobs.reduce((acc, job) => {
        if (!acc[job.conclusion]) {
          acc[job.conclusion] = 0;
        }
        acc[job.conclusion]++;
        return acc;
      }, {});

      const failedJobs = jobs.data.jobs.filter(job => job.conclusion === 'failure');

      return {
        success: true,
        runId: runId,
        workflow_name: runStatus.workflow_name,
        overall_conclusion: runStatus.conclusion,
        status: runStatus.status,
        job_summary: {
          total: jobs.data.jobs.length,
          conclusions: jobConclusions
        },
        failed_jobs: failedJobs.map(job => ({
          id: job.id,
          name: job.name,
          html_url: job.html_url
        })),
        html_url: runStatus.html_url
      };
    } catch (error) {
      console.error(`[StatusTracker] Error getting conclusion summary: ${error.message}`);
      throw new Error(`Failed to get conclusion summary for run ${runId}: ${error.message}`);
    }
  }
}

module.exports = StatusTracker;
