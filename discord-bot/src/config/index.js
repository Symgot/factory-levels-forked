require('dotenv').config();

module.exports = {
  discord: {
    token: process.env.DISCORD_TOKEN,
    clientId: process.env.DISCORD_CLIENT_ID,
    guildId: process.env.DISCORD_GUILD_ID,
    ticketCategoryId: process.env.TICKET_CATEGORY_ID
  },
  github: {
    token: process.env.GITHUB_TOKEN,
    repository: process.env.GITHUB_REPOSITORY,
    workflowDispatchUrl: process.env.GITHUB_WORKFLOW_DISPATCH_URL
  },
  upload: {
    maxFileSizeMB: parseInt(process.env.MAX_FILE_SIZE_MB) || 25,
    allowedExtensions: (process.env.ALLOWED_FILE_EXTENSIONS || '.zip,.lua').split(',')
  },
  authentication: {
    enabled: process.env.AUTH_ENABLED === 'true',
    githubAppId: process.env.GITHUB_APP_ID,
    githubAppPrivateKey: process.env.GITHUB_APP_PRIVATE_KEY
  }
};
