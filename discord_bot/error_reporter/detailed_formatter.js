function formatDetailedErrors(errors) {
  const embeds = [];

  for (const error of errors) {
    const embed = {
      title: `${getSeverityEmoji(error.severity)} ${error.category || 'Error'}`,
      description: error.message || 'No description provided',
      color: getSeverityColor(error.severity),
      fields: [],
      timestamp: new Date()
    };

    if (error.file) {
      embed.fields.push({ name: 'File', value: `\`${error.file}\``, inline: true });
    }

    if (error.line) {
      embed.fields.push({ name: 'Line', value: error.line.toString(), inline: true });
    }

    if (error.severity) {
      embed.fields.push({ name: 'Severity', value: error.severity.toUpperCase(), inline: true });
    }

    if (error.codeSnippet) {
      const snippet = error.codeSnippet.length > 500 
        ? error.codeSnippet.substring(0, 500) + '...'
        : error.codeSnippet;
      embed.fields.push({
        name: '📄 Code',
        value: `\`\`\`lua\n${snippet}\n\`\`\``,
        inline: false
      });
    }

    if (error.suggestion) {
      const suggestion = error.suggestion.length > 300
        ? error.suggestion.substring(0, 300) + '...'
        : error.suggestion;
      embed.fields.push({
        name: '💡 Fix Suggestion',
        value: suggestion,
        inline: false
      });
    }

    if (error.documentationUrl) {
      embed.fields.push({
        name: '📚 Documentation',
        value: error.documentationUrl,
        inline: false
      });
    }

    embeds.push(embed);
  }

  return embeds;
}

function formatSuccessMessage(results) {
  return {
    embeds: [{
      title: '✅ Analysis Complete - No Issues Found',
      description: 'Your mod passed all validation checks!',
      fields: [
        { name: 'Total Checks', value: results.summary?.total?.toString() || '0', inline: true },
        { name: 'Passed', value: results.summary?.passed?.toString() || '0', inline: true },
        { name: 'Duration', value: results.duration || 'N/A', inline: true }
      ],
      color: 0x00FF00,
      timestamp: new Date(),
      footer: { text: 'Powered by Factorify Analysis Engine' }
    }]
  };
}

function formatErrorSummary(results) {
  const errorsBySeverity = {
    critical: [],
    high: [],
    medium: [],
    low: [],
    info: []
  };

  for (const error of results.errors || []) {
    const severity = (error.severity || 'info').toLowerCase();
    if (errorsBySeverity[severity]) {
      errorsBySeverity[severity].push(error);
    }
  }

  const fields = [];

  if (errorsBySeverity.critical.length > 0) {
    fields.push({
      name: '🔴 Critical',
      value: errorsBySeverity.critical.map(e => `• ${e.message?.substring(0, 80) || 'Unknown error'}`).join('\n').substring(0, 1000),
      inline: false
    });
  }

  if (errorsBySeverity.high.length > 0) {
    fields.push({
      name: '🟠 High',
      value: errorsBySeverity.high.map(e => `• ${e.message?.substring(0, 80) || 'Unknown error'}`).join('\n').substring(0, 1000),
      inline: false
    });
  }

  if (errorsBySeverity.medium.length > 0) {
    fields.push({
      name: '🟡 Medium',
      value: errorsBySeverity.medium.map(e => `• ${e.message?.substring(0, 80) || 'Unknown error'}`).join('\n').substring(0, 1000),
      inline: false
    });
  }

  const totalErrors = Object.values(errorsBySeverity).reduce((sum, arr) => sum + arr.length, 0);

  return {
    embeds: [{
      title: '⚠️ Analysis Complete - Issues Found',
      description: `Found ${totalErrors} issue(s) in your mod`,
      fields: fields,
      color: errorsBySeverity.critical.length > 0 ? 0xFF0000 : 
             errorsBySeverity.high.length > 0 ? 0xFF6600 : 0xFFCC00,
      timestamp: new Date(),
      footer: { text: 'Scroll down for detailed error reports' }
    }]
  };
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
  formatDetailedErrors,
  formatSuccessMessage,
  formatErrorSummary,
  getSeverityEmoji,
  getSeverityColor
};
