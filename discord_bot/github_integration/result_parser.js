const AdmZip = require('adm-zip');

function parseAnalysisResults(artifactBuffer) {
  try {
    const zip = new AdmZip(artifactBuffer);
    const zipEntries = zip.getEntries();

    const resultsEntry = zipEntries.find(e => e.entryName === 'results.json');
    
    if (!resultsEntry) {
      throw new Error('results.json not found in artifact');
    }

    const resultsContent = resultsEntry.getData().toString('utf8');
    const results = JSON.parse(resultsContent);

    return {
      success: true,
      results: results
    };
  } catch (error) {
    console.error('[ResultParser] Error parsing results:', error);
    return {
      success: false,
      error: error.message
    };
  }
}

function formatResultsForDiscord(results) {
  const embeds = [];

  if (results.summary) {
    embeds.push({
      title: '📊 Analysis Summary',
      fields: [
        { name: 'Total Checks', value: results.summary.total?.toString() || '0', inline: true },
        { name: 'Passed', value: results.summary.passed?.toString() || '0', inline: true },
        { name: 'Failed', value: results.summary.failed?.toString() || '0', inline: true }
      ],
      color: results.summary.passed === results.summary.total ? 0x00FF00 : 0xFFA500,
      timestamp: new Date()
    });
  }

  if (results.errors && results.errors.length > 0) {
    for (const error of results.errors.slice(0, 5)) {
      embeds.push({
        title: `${getSeverityEmoji(error.severity)} ${error.category || 'Error'}`,
        description: error.message || 'No description',
        fields: [
          { name: 'File', value: `\`${error.file || 'Unknown'}\``, inline: true },
          { name: 'Line', value: error.line?.toString() || 'N/A', inline: true },
          { name: 'Severity', value: error.severity || 'unknown', inline: true }
        ],
        color: getSeverityColor(error.severity),
        timestamp: new Date()
      });

      if (error.codeSnippet) {
        embeds[embeds.length - 1].fields.push({
          name: 'Code',
          value: `\`\`\`lua\n${error.codeSnippet.substring(0, 500)}\n\`\`\``,
          inline: false
        });
      }

      if (error.suggestion) {
        embeds[embeds.length - 1].fields.push({
          name: '💡 Suggestion',
          value: error.suggestion.substring(0, 200),
          inline: false
        });
      }
    }

    if (results.errors.length > 5) {
      embeds.push({
        title: '⚠️ Additional Errors',
        description: `${results.errors.length - 5} more error(s) not shown. Check the full report for details.`,
        color: 0xFFA500
      });
    }
  }

  return embeds;
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
  parseAnalysisResults,
  formatResultsForDiscord,
  getSeverityEmoji,
  getSeverityColor
};
