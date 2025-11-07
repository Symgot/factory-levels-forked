# Factorify Discord Bot

Discord bot for Factorio mod analysis with GitHub Actions integration and ticket system.

## Features

- **File Upload Support**: Upload `.lua`, `.zip`, `.tar.gz` mod files directly in Discord
- **Private Ticket System**: Each user gets a private channel for their analysis
- **GitHub Actions Integration**: Triggers workflows on the Factorify repository
- **Real-time Updates**: Status updates posted directly in ticket channels
- **Detailed Error Reporting**: Line-level errors with code snippets and fix suggestions
- **Auto-cleanup**: Tickets auto-close after 7 days of inactivity

## Commands

### `/analyze`
Upload and analyze a Factorio mod.

**Options:**
- `file` (required): Mod archive or Lua file (.lua, .zip, .tar.gz)
- `description` (optional): Notes about the mod

**Example:**
```
/analyze file:my-mod.zip description:"My custom transport belt mod"
```

### `/status`
Check the status of your analysis tickets.

**Options:**
- `ticket-id` (optional): Specific ticket ID to check

**Examples:**
```
/status
/status ticket-id:ticket-1234567890
```

### `/help`
Display help information about bot commands.

### `/config` (Admin only)
Configure bot settings.

**Subcommands:**
- `view`: View current configuration
- `set-category`: Set ticket category name
- `set-webhook`: Configure Discord webhook for results

## Setup

### Prerequisites

- Node.js 18.x or higher
- Discord Bot Token
- GitHub Personal Access Token or GitHub App credentials
- Discord Guild (Server) ID

### Installation

1. Clone the repository:
```bash
cd discord_bot
npm install
```

2. Create `.env` file:
```env
DISCORD_BOT_TOKEN=your_discord_bot_token
DISCORD_CLIENT_ID=your_discord_client_id
DISCORD_GUILD_ID=your_guild_id
GITHUB_TOKEN=your_github_token
GITHUB_OWNER=Symgot
GITHUB_REPO=Factorify
DISCORD_WEBHOOK_URL=your_webhook_url (optional)
```

3. Deploy slash commands:
```bash
npm run deploy-commands
```

4. Start the bot:
```bash
npm start
```

For development with auto-reload:
```bash
npm run dev
```

## Architecture

```
discord_bot/
├── bot.js                      # Main bot logic
├── commands/                   # Slash commands
│   ├── analyze.js             # File upload & analysis
│   ├── status.js              # Ticket status checker
│   ├── help.js                # Help command
│   └── config.js              # Bot configuration
├── ticket_system/             # Ticket management
│   └── ticket_manager.js      # Ticket CRUD operations
├── file_handler/              # File processing
│   └── upload_handler.js      # Archive extraction
├── github_integration/        # GitHub Actions
│   ├── workflow_trigger.js   # Trigger workflows
│   └── result_parser.js      # Parse analysis results
├── error_reporter/            # Error formatting
│   ├── detailed_formatter.js # Format errors
│   └── embed_generator.js    # Create Discord embeds
└── data/                      # Persistent storage
    └── tickets.json           # Ticket database
```

## Workflow

### Analysis Flow

1. **User uploads file** via `/analyze` command
2. **Ticket created** - Private channel with user-only access
3. **File extracted** - Archive contents processed
4. **GitHub Actions triggered** - Workflow dispatch to Factorify repo
5. **Status updates** - Posted in ticket channel
6. **Results delivered** - Detailed error reports with suggestions
7. **Ticket auto-closes** - After 7 days of inactivity

### Ticket Permissions

- **User**: View, send messages, read history
- **Bot**: View, send messages, manage channel
- **Moderators**: View, send messages
- **Everyone else**: No access

## GitHub Actions Integration

The bot triggers the `standalone_validation.yml` workflow with these inputs:

- `ticket_id`: Unique ticket identifier
- `mod_files`: Base64-encoded mod content
- `file_count`: Number of files
- `total_size`: Total file size
- `discord_webhook`: Webhook URL for result notifications

## Error Reporting

Errors are categorized by severity:

- 🔴 **Critical**: Must fix (breaking issues)
- 🟠 **High**: Should fix (major problems)
- 🟡 **Medium**: Could fix (minor issues)
- 🟢 **Low**: Nice to fix (suggestions)
- ℹ️ **Info**: Informational messages

Each error includes:
- File name and line number
- Code snippet (up to 500 characters)
- Fix suggestion
- Documentation link (if available)

## Ticket System

### Ticket Schema

```json
{
  "id": "ticket-1234567890-5678",
  "userId": "123456789",
  "userName": "username",
  "guildId": "987654321",
  "channelId": "555555555",
  "fileName": "my-mod.zip",
  "fileUrl": "https://cdn.discord.com/...",
  "fileSize": 1024000,
  "description": "My mod",
  "status": "pending|analyzing|completed|failed|cancelled",
  "createdAt": "2024-11-07T12:00:00.000Z",
  "lastActivity": "2024-11-07T12:05:00.000Z",
  "closedAt": null,
  "results": {
    "passed": 10,
    "failed": 2
  }
}
```

### Status Values

- `pending`: Ticket created, waiting to start
- `analyzing`: Analysis in progress
- `completed`: Analysis finished successfully
- `failed`: Analysis failed with errors
- `cancelled`: Analysis cancelled by user

## Data Storage

Tickets are stored in `data/tickets.json` as a flat JSON object:

```json
{
  "ticket-1234567890-5678": { /* ticket data */ },
  "ticket-0987654321-1234": { /* ticket data */ }
}
```

For production, consider migrating to:
- MongoDB
- PostgreSQL
- Redis

## Security

- Private ticket channels prevent information leakage
- File size limit: 10 MB
- Allowed file types: `.lua`, `.zip`, `.tar.gz`, `.tar`
- Content validation before processing
- No executable files allowed

## Performance

- Archive extraction: < 2s for typical mods
- GitHub workflow trigger: < 1s
- Ticket creation: < 500ms
- Status updates: Real-time via Discord gateway

## Monitoring

The bot logs all activities:

```
[Bot] Logged in as Factorify#1234
[Analyze] Processing file: my-mod.zip (1024000 bytes) from username#5678
[TicketManager] Created ticket ticket-1234567890 for user username#5678
[WorkflowTrigger] Triggered workflow for ticket ticket-1234567890
[WorkflowTrigger] Workflow triggered successfully. Run ID: 123456
```

## Error Handling

All commands include try-catch blocks with:
- User-friendly error messages
- Detailed console logging
- Graceful degradation
- Ephemeral error responses

## Development

### Adding New Commands

1. Create `commands/mycommand.js`:
```javascript
const { SlashCommandBuilder } = require('discord.js');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('mycommand')
    .setDescription('My command description'),
  
  async execute(interaction, bot) {
    await interaction.reply('Hello!');
  }
};
```

2. Deploy commands:
```bash
npm run deploy-commands
```

3. Restart bot

### Testing

Test individual components:

```javascript
const { extractFiles } = require('./file_handler/upload_handler');

const testFile = {
  name: 'test.zip',
  url: 'https://example.com/test.zip',
  size: 1024
};

extractFiles(testFile).then(result => {
  console.log('Extracted:', result.files.length, 'files');
});
```

## Troubleshooting

### Bot not responding
- Check `DISCORD_BOT_TOKEN` is valid
- Verify bot has proper permissions in guild
- Check bot is online in Discord

### Commands not showing
- Run `npm run deploy-commands`
- Verify `DISCORD_CLIENT_ID` and `DISCORD_GUILD_ID`
- Wait up to 1 hour for global commands

### File upload fails
- Check file size (max 10 MB)
- Verify file type is supported
- Ensure bot has attachment permissions

### GitHub workflow not triggered
- Verify `GITHUB_TOKEN` has workflow permissions
- Check `GITHUB_OWNER` and `GITHUB_REPO` are correct
- Ensure workflow file exists in target repo

## License

MIT

## Support

For issues and questions:
- GitHub Issues: https://github.com/Symgot/Factorify/issues
- Discord Server: (Add your server invite)

## Credits

- Discord.js v14
- GitHub Actions
- Factorify Analysis Engine
