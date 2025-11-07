const { EmbedBuilder } = require('discord.js');

function createAnalysisStartEmbed(fileData) {
  return new EmbedBuilder()
    .setTitle('⏳ Analysis Started')
    .setDescription(`Analyzing mod file: \`${fileData.fileName}\``)
    .addFields([
      { name: 'File Size', value: `${(fileData.fileSize / 1024).toFixed(2)} KB`, inline: true },
      { name: 'File Count', value: fileData.fileCount?.toString() || '1', inline: true },
      { name: 'Status', value: '🔄 Downloading...', inline: false }
    ])
    .setColor(0xFFA500)
    .setTimestamp();
}

function createWorkflowTriggerEmbed(workflowData) {
  return new EmbedBuilder()
    .setTitle('🚀 GitHub Actions Triggered')
    .setDescription('Your mod is being analyzed on GitHub Actions')
    .addFields([
      { name: 'Workflow', value: workflowData.workflowId || 'standalone_validation.yml', inline: true },
      { name: 'Run ID', value: workflowData.runId?.toString() || 'Pending', inline: true },
      { name: 'Status', value: '⏳ Running...', inline: false }
    ])
    .setColor(0x0099FF)
    .setTimestamp()
    .setFooter({ text: 'You will be notified when analysis is complete' });
}

function createAnalysisCompleteEmbed(results) {
  const hasErrors = results.errors && results.errors.length > 0;
  
  const embed = new EmbedBuilder()
    .setTitle(hasErrors ? '⚠️ Analysis Complete - Issues Found' : '✅ Analysis Complete - All Checks Passed')
    .setDescription(hasErrors 
      ? `Found ${results.errors.length} issue(s) in your mod` 
      : 'Your mod passed all validation checks!')
    .setColor(hasErrors ? 0xFF6600 : 0x00FF00)
    .setTimestamp();

  if (results.summary) {
    embed.addFields([
      { name: 'Total Checks', value: results.summary.total?.toString() || '0', inline: true },
      { name: 'Passed', value: results.summary.passed?.toString() || '0', inline: true },
      { name: 'Failed', value: results.summary.failed?.toString() || '0', inline: true }
    ]);
  }

  if (results.duration) {
    embed.addFields({ name: 'Duration', value: results.duration, inline: true });
  }

  return embed;
}

function createErrorEmbed(error) {
  const embed = new EmbedBuilder()
    .setTitle(`${getSeverityEmoji(error.severity)} ${error.category || 'Error'}`)
    .setDescription(error.message || 'No description')
    .setColor(getSeverityColor(error.severity))
    .setTimestamp();

  if (error.file) {
    embed.addFields({ name: 'File', value: `\`${error.file}\``, inline: true });
  }

  if (error.line) {
    embed.addFields({ name: 'Line', value: error.line.toString(), inline: true });
  }

  if (error.severity) {
    embed.addFields({ name: 'Severity', value: error.severity.toUpperCase(), inline: true });
  }

  if (error.codeSnippet) {
    const snippet = error.codeSnippet.length > 500
      ? error.codeSnippet.substring(0, 500) + '...'
      : error.codeSnippet;
    embed.addFields({
      name: '📄 Code',
      value: `\`\`\`lua\n${snippet}\n\`\`\``,
      inline: false
    });
  }

  if (error.suggestion) {
    embed.addFields({
      name: '💡 Fix Suggestion',
      value: error.suggestion.substring(0, 300),
      inline: false
    });
  }

  return embed;
}

function createProgressEmbed(status) {
  const statusEmojis = {
    queued: '⏸️',
    in_progress: '🔄',
    completed: '✅',
    cancelled: '🚫',
    failure: '❌'
  };

  const statusColors = {
    queued: 0x808080,
    in_progress: 0x0099FF,
    completed: 0x00FF00,
    cancelled: 0x808080,
    failure: 0xFF0000
  };

  return new EmbedBuilder()
    .setTitle('📊 Analysis Progress')
    .setDescription(`Current status: ${statusEmojis[status.status] || '❓'} ${status.status}`)
    .addFields([
      { name: 'Workflow', value: status.workflow_name || 'N/A', inline: true },
      { name: 'Started', value: status.run_started_at ? `<t:${Math.floor(new Date(status.run_started_at).getTime() / 1000)}:R>` : 'N/A', inline: true }
    ])
    .setColor(statusColors[status.status] || 0x808080)
    .setTimestamp();
}

function createFailureEmbed(error) {
  return new EmbedBuilder()
    .setTitle('❌ Analysis Failed')
    .setDescription(`Failed to analyze mod: ${error.message || 'Unknown error'}`)
    .setColor(0xFF0000)
    .setTimestamp()
    .setFooter({ text: 'Please try again or contact support' });
}

function getSeverityEmoji(severity) {
  const emojis = {
    critical: '🔴',
    high: '🟠',
    medium: '🟡',
    low: '🟢',
    info: 'ℹ️'
  };
  return emojis[severity?.toLowerCase()] || 'ℹ️';
}

function getSeverityColor(severity) {
  const colors = {
    critical: 0xFF0000,
    high: 0xFF6600,
    medium: 0xFFCC00,
    low: 0x00FF00,
    info: 0x0099FF
  };
  return colors[severity?.toLowerCase()] || 0x808080;
}

module.exports = {
  createAnalysisStartEmbed,
  createWorkflowTriggerEmbed,
  createAnalysisCompleteEmbed,
  createErrorEmbed,
  createProgressEmbed,
  createFailureEmbed,
  getSeverityEmoji,
  getSeverityColor
};
