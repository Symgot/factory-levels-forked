# Discord Bot Integration

## Overview

The Factorify Discord Bot provides an interactive interface for mod analysis through Discord, with automatic GitHub Actions workflow triggering for comprehensive validation and testing.

## Features

### Ticket System
- Private ticket channels per user
- Automatic channel creation/deletion
- Persistent ticket tracking
- User-specific permissions

### File Upload Support
- **Mod Archives (.zip)**: Full mod analysis
- **Lua Scripts (.lua)**: Syntax validation and pattern detection
- Maximum file size: 25MB
- Automatic validation and processing

### GitHub Actions Integration
- Automatic workflow dispatch on file upload
- Real-time status updates
- Detailed analysis results posted to Discord
- Artifact storage for downloads

## Installation

### Prerequisites
- Node.js 18+ 
- Discord Bot Token
- GitHub Personal Access Token
- Discord Server with Admin permissions

### Setup

1. **Install dependencies:**
```bash
cd discord-bot
npm install
```

2. **Configure environment:**
```bash
cp .env.example .env
# Edit .env with your credentials
```

3. **Required Environment Variables:**
- `DISCORD_TOKEN`: Your Discord bot token
- `DISCORD_CLIENT_ID`: Discord application client ID
- `DISCORD_GUILD_ID`: Target Discord server ID
- `GITHUB_TOKEN`: GitHub PAT with `actions:write` permission
- `GITHUB_REPOSITORY`: Target repository (e.g., `owner/repo`)
- `TICKET_CATEGORY_ID`: Discord category for ticket channels
- `DISCORD_WEBHOOK_URL`: Webhook URL for posting results

4. **Register slash commands:**
```bash
node src/utils/deploy-commands.js
```

5. **Start the bot:**
```bash
npm start
```

## Commands

### `/analyze-mod`
Creates a private ticket channel for mod analysis.

**Usage:**
1. Run `/analyze-mod` in any channel
2. Bot creates a private ticket channel
3. Upload mod files (.zip or .lua)
4. Bot triggers GitHub Actions workflows
5. Results are posted automatically

### `/close-ticket`
Closes your active ticket channel.

**Usage:**
- Run `/close-ticket` inside your ticket channel
- Channel is deleted after 5 seconds

## Workflow Integration

### Mod Analysis Workflow (`mod-analysis.yml`)
Triggered when a `.zip` file is uploaded.

**Process:**
1. Download and extract mod archive
2. Validate mod structure
3. Check for info.json
4. Analyze Lua files
5. Generate detailed report
6. Post results to Discord

**Inputs:**
- `file_url`: URL of the uploaded file
- `file_name`: Original filename
- `ticket_id`: Discord channel ID
- `user_id`: Discord user ID

### Lua Validation Workflow (`lua-validation.yml`)
Triggered when a `.lua` file is uploaded.

**Process:**
1. Download Lua file
2. Syntax validation with Lua interpreter
3. Static analysis with luacheck
4. Pattern detection (Factorio-specific)
5. Generate validation report
6. Post results to Discord

## Architecture

### Discord Bot Flow
```
User -> /analyze-mod -> Create Ticket Channel
   |
   v
Upload File -> Validate -> Trigger GitHub Actions
   |
   v
GitHub Actions -> Process -> Generate Report
   |
   v
Discord Webhook -> Post Results -> User Notified
```

### Authentication Options

The bot supports **optional authentication**:

**Default (No Auth):**
- Uses public GitHub API
- Perfect for public repositories
- No special permissions required
- Workflows run with repository secrets

**With Auth (GitHub App):**
- Enhanced rate limits
- Cross-repository access
- Installation-based tokens
- Automatically managed

Enable authentication:
```bash
AUTH_ENABLED=true
GITHUB_APP_ID=your_app_id
GITHUB_APP_PRIVATE_KEY=your_private_key
```

## Security

- Private ticket channels (user-specific permissions)
- File size limits (25MB default)
- File type validation
- GitHub Actions run in isolated environments
- Webhook signature verification
- Token encryption in transit

## Error Handling

### File Upload Errors
- **Invalid file type**: Bot responds with allowed types
- **File too large**: Bot responds with size limit
- **Network error**: Retries automatically

### Workflow Errors
- Failed workflows post error details to Discord
- Logs available as GitHub Actions artifacts
- User receives notification with troubleshooting steps

## Configuration

### File Size Limit
Change in `.env`:
```
MAX_FILE_SIZE_MB=50
```

### Allowed Extensions
Change in `.env`:
```
ALLOWED_FILE_EXTENSIONS=.zip,.lua,.json
```

### Ticket Category
Set Discord category ID for tickets:
```
TICKET_CATEGORY_ID=1234567890
```

## Monitoring

### Bot Status
Check bot status in console output:
```
Discord bot ready. Logged in as FactorifyBot#1234
GitHub Actions integration: Public
```

### Metrics
Monitor ticket activity:
```javascript
console.log(client.tickets.size); // Active tickets
```

## Troubleshooting

### Bot not responding
1. Check Discord token validity
2. Verify bot has necessary permissions
3. Check console for errors

### Workflow not triggering
1. Verify `GITHUB_TOKEN` has `actions:write` scope
2. Check workflow file exists in repository
3. Verify repository name format: `owner/repo`

### Results not posting
1. Check `DISCORD_WEBHOOK_URL` validity
2. Verify webhook has permission to post
3. Check GitHub Actions logs for errors

## Development

### Running in dev mode
```bash
npm run dev
```

### Testing
```bash
npm test
```

## Future Enhancements

- Multi-file uploads
- Batch processing
- Custom validation rules
- Interactive workflow configuration
- Real-time progress updates
- Collaborative analysis sessions

## Support

For issues or questions:
- Open an issue in the repository
- Check GitHub Discussions
- Review workflow logs in GitHub Actions
