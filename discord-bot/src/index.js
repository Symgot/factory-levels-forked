const { Client, GatewayIntentBits, Collection, Events, ChannelType, PermissionFlagsBits } = require('discord.js');
const config = require('./config');
const { Octokit } = require('@octokit/rest');

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
    GatewayIntentBits.GuildMembers
  ]
});

client.commands = new Collection();
client.tickets = new Map();

const octokit = new Octokit({
  auth: config.github.token
});

client.once(Events.ClientReady, readyClient => {
  console.log(`Discord bot ready. Logged in as ${readyClient.user.tag}`);
  console.log(`GitHub Actions integration: ${config.authentication.enabled ? 'Authenticated' : 'Public'}`);
});

client.on(Events.InteractionCreate, async interaction => {
  if (!interaction.isChatInputCommand()) return;

  const command = client.commands.get(interaction.commandName);
  if (!command) return;

  try {
    await command.execute(interaction, octokit);
  } catch (error) {
    console.error('Command execution error:', error);
    const reply = { content: 'Error executing command', ephemeral: true };
    if (interaction.replied || interaction.deferred) {
      await interaction.followUp(reply);
    } else {
      await interaction.reply(reply);
    }
  }
});

client.on(Events.MessageCreate, async message => {
  if (message.author.bot) return;
  
  const ticket = client.tickets.get(message.channel.id);
  if (!ticket) return;

  if (message.attachments.size > 0) {
    const attachment = message.attachments.first();
    const fileExt = attachment.name.substring(attachment.name.lastIndexOf('.')).toLowerCase();
    
    if (!config.upload.allowedExtensions.includes(fileExt)) {
      await message.reply(`Invalid file type. Allowed: ${config.upload.allowedExtensions.join(', ')}`);
      return;
    }

    const fileSizeMB = attachment.size / (1024 * 1024);
    if (fileSizeMB > config.upload.maxFileSizeMB) {
      await message.reply(`File too large. Maximum: ${config.upload.maxFileSizeMB}MB`);
      return;
    }

    await message.reply('Processing file... Triggering GitHub Actions workflow.');
    
    try {
      const [owner, repo] = config.github.repository.split('/');
      const workflowId = fileExt === '.zip' ? 'mod-analysis.yml' : 'lua-validation.yml';
      
      await octokit.actions.createWorkflowDispatch({
        owner,
        repo,
        workflow_id: workflowId,
        ref: 'main',
        inputs: {
          file_url: attachment.url,
          file_name: attachment.name,
          ticket_id: message.channel.id,
          user_id: message.author.id
        }
      });

      await message.reply('✅ GitHub Actions workflow triggered. Results will be posted here.');
    } catch (error) {
      console.error('Workflow dispatch error:', error);
      await message.reply('❌ Failed to trigger analysis workflow.');
    }
  }
});

const commands = require('./commands');
for (const command of commands) {
  client.commands.set(command.data.name, command);
}

client.login(config.discord.token);
