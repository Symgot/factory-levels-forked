const { Octokit } = require('@octokit/rest');

/**
 * WorkflowDispatcher - Direct GitHub Actions workflow_dispatch integration
 * NO external API server required - 100% GitHub-native
 */
class WorkflowDispatcher {
  constructor(token, owner, repo) {
    this.octokit = new Octokit({ auth: token });
    this.owner = owner;
    this.repo = repo;
  }

  /**
   * Trigger a workflow using workflow_dispatch event
   * @param {string} workflowId - Workflow ID or filename (e.g., 'standalone_validation.yml')
   * @param {object} inputs - Input parameters for the workflow
   * @param {string} ref - Git ref (branch/tag) to run workflow on
   * @returns {Promise<object>} - Response from GitHub API
   */
  async triggerWorkflow(workflowId, inputs = {}, ref = 'main') {
    // Validate inputs
    if (!workflowId || typeof workflowId !== 'string') {
      throw new Error('workflowId must be a non-empty string');
    }
    
    if (typeof inputs !== 'object' || inputs === null) {
      throw new Error('inputs must be an object');
    }
    
    if (!ref || typeof ref !== 'string') {
      throw new Error('ref must be a non-empty string');
    }

    try {
      const response = await this.octokit.rest.actions.createWorkflowDispatch({
        owner: this.owner,
        repo: this.repo,
        workflow_id: workflowId,
        ref: ref,
        inputs: inputs
      });

      console.log(`[WorkflowDispatcher] Triggered workflow ${workflowId} on ${ref}`);
      return {
        success: true,
        workflowId: workflowId,
        ref: ref,
        inputs: inputs,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error(`[WorkflowDispatcher] Error triggering workflow: ${error.message}`);
      throw new Error(`Failed to trigger workflow ${workflowId}: ${error.message}`);
    }
  }

  /**
   * List all workflow runs for a specific workflow
   * @param {string} workflowId - Workflow ID or filename
   * @param {object} options - Filter options (status, branch, event, etc.)
   * @returns {Promise<object>} - List of workflow runs
   */
  async listWorkflowRuns(workflowId, options = {}) {
    try {
      const params = {
        owner: this.owner,
        repo: this.repo,
        workflow_id: workflowId,
        per_page: options.perPage || 30,
        page: options.page || 1
      };

      if (options.status) params.status = options.status;
      if (options.branch) params.branch = options.branch;
      if (options.event) params.event = options.event;

      const response = await this.octokit.rest.actions.listWorkflowRuns(params);

      return {
        success: true,
        total_count: response.data.total_count,
        workflow_runs: response.data.workflow_runs.map(run => ({
          id: run.id,
          name: run.name,
          status: run.status,
          conclusion: run.conclusion,
          created_at: run.created_at,
          updated_at: run.updated_at,
          html_url: run.html_url
        }))
      };
    } catch (error) {
      console.error(`[WorkflowDispatcher] Error listing workflow runs: ${error.message}`);
      throw new Error(`Failed to list workflow runs for ${workflowId}: ${error.message}`);
    }
  }

  /**
   * Get the latest workflow run for a specific workflow
   * @param {string} workflowId - Workflow ID or filename
   * @param {string} branch - Branch to filter by (optional)
   * @returns {Promise<object|null>} - Latest workflow run or null
   */
  async getLatestWorkflowRun(workflowId, branch = null) {
    try {
      const options = {
        perPage: 1,
        page: 1
      };
      
      if (branch) options.branch = branch;

      const result = await this.listWorkflowRuns(workflowId, options);
      
      if (result.workflow_runs && result.workflow_runs.length > 0) {
        return result.workflow_runs[0];
      }
      
      return null;
    } catch (error) {
      console.error(`[WorkflowDispatcher] Error getting latest workflow run: ${error.message}`);
      return null;
    }
  }

  /**
   * Get workflow run by ID
   * @param {number} runId - Workflow run ID
   * @returns {Promise<object>} - Workflow run details
   */
  async getWorkflowRun(runId) {
    try {
      const response = await this.octokit.rest.actions.getWorkflowRun({
        owner: this.owner,
        repo: this.repo,
        run_id: runId
      });

      return {
        success: true,
        id: response.data.id,
        name: response.data.name,
        status: response.data.status,
        conclusion: response.data.conclusion,
        created_at: response.data.created_at,
        updated_at: response.data.updated_at,
        html_url: response.data.html_url,
        jobs_url: response.data.jobs_url,
        logs_url: response.data.logs_url,
        artifacts_url: response.data.artifacts_url
      };
    } catch (error) {
      console.error(`[WorkflowDispatcher] Error getting workflow run: ${error.message}`);
      throw new Error(`Failed to get workflow run ${runId}: ${error.message}`);
    }
  }

  /**
   * Cancel a workflow run
   * @param {number} runId - Workflow run ID to cancel
   * @returns {Promise<object>} - Cancellation result
   */
  async cancelWorkflowRun(runId) {
    try {
      await this.octokit.rest.actions.cancelWorkflowRun({
        owner: this.owner,
        repo: this.repo,
        run_id: runId
      });

      console.log(`[WorkflowDispatcher] Cancelled workflow run ${runId}`);
      return {
        success: true,
        runId: runId,
        message: 'Workflow run cancelled successfully'
      };
    } catch (error) {
      console.error(`[WorkflowDispatcher] Error cancelling workflow run: ${error.message}`);
      throw new Error(`Failed to cancel workflow run ${runId}: ${error.message}`);
    }
  }

  /**
   * Download workflow run artifacts
   * @param {number} artifactId - Artifact ID to download
   * @returns {Promise<Buffer>} - Artifact data as buffer
   */
  async downloadArtifact(artifactId) {
    try {
      const response = await this.octokit.rest.actions.downloadArtifact({
        owner: this.owner,
        repo: this.repo,
        artifact_id: artifactId,
        archive_format: 'zip'
      });

      console.log(`[WorkflowDispatcher] Downloaded artifact ${artifactId}`);
      return response.data;
    } catch (error) {
      console.error(`[WorkflowDispatcher] Error downloading artifact: ${error.message}`);
      throw new Error(`Failed to download artifact ${artifactId}: ${error.message}`);
    }
  }

  /**
   * List artifacts for a workflow run
   * @param {number} runId - Workflow run ID
   * @returns {Promise<object>} - List of artifacts
   */
  async listWorkflowRunArtifacts(runId) {
    try {
      const response = await this.octokit.rest.actions.listWorkflowRunArtifacts({
        owner: this.owner,
        repo: this.repo,
        run_id: runId
      });

      return {
        success: true,
        total_count: response.data.total_count,
        artifacts: response.data.artifacts.map(artifact => ({
          id: artifact.id,
          name: artifact.name,
          size_in_bytes: artifact.size_in_bytes,
          created_at: artifact.created_at,
          expired: artifact.expired
        }))
      };
    } catch (error) {
      console.error(`[WorkflowDispatcher] Error listing artifacts: ${error.message}`);
      throw new Error(`Failed to list artifacts for run ${runId}: ${error.message}`);
    }
  }
}

module.exports = WorkflowDispatcher;
