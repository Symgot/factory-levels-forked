const { WorkflowDispatcher } = require('../../github_actions_integration');

async function triggerAnalysis(ticketId, fileData, config) {
  console.log(`[WorkflowTrigger] Triggering analysis for ticket ${ticketId}`);

  try {
    const dispatcher = new WorkflowDispatcher(
      config.githubToken,
      config.owner,
      config.repo
    );

    const combinedContent = fileData.files.map(f => f.content).join('\n\n');
    const base64Content = Buffer.from(combinedContent).toString('base64');

    const workflowInputs = {
      ticket_id: ticketId,
      mod_files: base64Content,
      file_count: fileData.files.length.toString(),
      total_size: fileData.totalSize.toString(),
      discord_webhook: config.webhookUrl || ''
    };

    const result = await dispatcher.triggerWorkflow(
      'standalone_validation.yml',
      workflowInputs,
      'main'
    );

    await new Promise(resolve => setTimeout(resolve, 2000));

    const latestRun = await dispatcher.getLatestWorkflowRun('standalone_validation.yml', 'main');

    console.log(`[WorkflowTrigger] Workflow triggered successfully. Run ID: ${latestRun?.id || 'Unknown'}`);

    return {
      success: true,
      runId: latestRun?.id || null,
      workflowId: 'standalone_validation.yml',
      ticketId: ticketId,
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    console.error('[WorkflowTrigger] Error triggering workflow:', error);
    return {
      success: false,
      error: error.message,
      ticketId: ticketId
    };
  }
}

async function getAnalysisStatus(runId, config) {
  try {
    const dispatcher = new WorkflowDispatcher(
      config.githubToken,
      config.owner,
      config.repo
    );

    const status = await dispatcher.getWorkflowRun(runId);

    return {
      success: true,
      runId: runId,
      status: status.status,
      conclusion: status.conclusion,
      url: status.html_url
    };
  } catch (error) {
    console.error('[WorkflowTrigger] Error getting status:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

async function downloadAnalysisResults(runId, config) {
  try {
    const dispatcher = new WorkflowDispatcher(
      config.githubToken,
      config.owner,
      config.repo
    );

    const artifacts = await dispatcher.listWorkflowRunArtifacts(runId);

    if (artifacts.total_count === 0) {
      return {
        success: false,
        error: 'No artifacts found'
      };
    }

    const resultArtifact = artifacts.artifacts.find(a => a.name === 'analysis-results');

    if (!resultArtifact) {
      return {
        success: false,
        error: 'Analysis results artifact not found'
      };
    }

    const artifactData = await dispatcher.downloadArtifact(resultArtifact.id);

    return {
      success: true,
      artifactId: resultArtifact.id,
      data: artifactData
    };
  } catch (error) {
    console.error('[WorkflowTrigger] Error downloading results:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

module.exports = {
  triggerAnalysis,
  getAnalysisStatus,
  downloadAnalysisResults
};
