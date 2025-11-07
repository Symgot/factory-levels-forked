const { Client, GatewayIntentBits, Partials, Collection, ActivityType } = require('discord.js');
const fs = require('fs');
const path = require('path');

/**
 * Factorify Discord Bot - Mod Analysis & Ticket System
 * Main bot logic with Discord.js v14
 */
class FactorifyBot {
  constructor() {
    this.client = new Client({
      intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.GuildMembers,
        GatewayIntentBits.DirectMessages
      ],
      partials: [
        Partials.Channel,
        Partials.Message
      ]
    });

    this.commands = new Collection();
    this.config = {
      token: process.env.DISCORD_BOT_TOKEN,
      clientId: process.env.DISCORD_CLIENT_ID,
      guildId: process.env.DISCORD_GUILD_ID,
      githubToken: process.env.GITHUB_TOKEN,
      githubOwner: process.env.GITHUB_OWNER || 'Symgot',
      githubRepo: process.env.GITHUB_REPO || 'Factorify'
    };
  }

  async loadCommands() {
    const commandsPath = path.join(__dirname, 'commands');
    const commandFiles = fs.readdirSync(commandsPath).filter(file => file.endsWith('.js'));

    for (const file of commandFiles) {
      const filePath = path.join(commandsPath, file);
      const command = require(filePath);
      
      if ('data' in command && 'execute' in command) {
        this.commands.set(command.data.name, command);
        console.log(`[Bot] Loaded command: ${command.data.name}`);
      } else {
        console.warn(`[Bot] Command at ${filePath} is missing required "data" or "execute" property`);
      }
    }
  }

  setupEventHandlers() {
    this.client.once('ready', () => {
      console.log(`[Bot] Logged in as ${this.client.user.tag}`);
      console.log(`[Bot] Serving ${this.client.guilds.cache.size} guilds`);
      
      this.client.user.setActivity('Factorio mods', { type: ActivityType.Watching });
    });

    this.client.on('interactionCreate', async interaction => {
      if (interaction.isChatInputCommand()) {
        await this.handleCommand(interaction);
      } else if (interaction.isModalSubmit()) {
        await this.handleModalSubmit(interaction);
      } else if (interaction.isButton()) {
        await this.handleButton(interaction);
      }
    });

    this.client.on('error', error => {
      console.error('[Bot] Discord client error:', error);
    });

    this.client.on('warn', warning => {
      console.warn('[Bot] Discord client warning:', warning);
    });
  }

  async handleCommand(interaction) {
    const command = this.commands.get(interaction.commandName);

    if (!command) {
      console.warn(`[Bot] Command not found: ${interaction.commandName}`);
      await interaction.reply({
        content: 'Command not found.',
        ephemeral: true
      });
      return;
    }

    try {
      console.log(`[Bot] Executing command: ${interaction.commandName} by ${interaction.user.tag}`);
      await command.execute(interaction, this);
    } catch (error) {
      console.error(`[Bot] Error executing command ${interaction.commandName}:`, error);
      
      const errorResponse = {
        content: 'An error occurred while executing this command.',
        ephemeral: true
      };

      if (interaction.replied || interaction.deferred) {
        await interaction.followUp(errorResponse);
      } else {
        await interaction.reply(errorResponse);
      }
    }
  }

  async handleModalSubmit(interaction) {
    if (interaction.customId === 'analyze_modal') {
      try {
        const analyzeCommand = this.commands.get('analyze');
        if (analyzeCommand && analyzeCommand.handleModalSubmit) {
          await analyzeCommand.handleModalSubmit(interaction, this);
        }
      } catch (error) {
        console.error('[Bot] Error handling modal submit:', error);
        await interaction.reply({
          content: 'An error occurred while processing your submission.',
          ephemeral: true
        });
      }
    }
  }

  async handleButton(interaction) {
    if (interaction.customId.startsWith('close_ticket_')) {
      try {
        const ticketId = interaction.customId.replace('close_ticket_', '');
        const { closeTicket } = require('./ticket_system/ticket_manager');
        await closeTicket(interaction.guild, ticketId);
        await interaction.reply({ content: 'Ticket closed successfully.', ephemeral: true });
      } catch (error) {
        console.error('[Bot] Error closing ticket:', error);
        await interaction.reply({ content: 'Failed to close ticket.', ephemeral: true });
      }
    }
  }

  async start() {
    if (!this.config.token) {
      throw new Error('DISCORD_BOT_TOKEN is not set in environment variables');
    }

    console.log('[Bot] Loading commands...');
    await this.loadCommands();

    console.log('[Bot] Setting up event handlers...');
    this.setupEventHandlers();

    console.log('[Bot] Logging in to Discord...');
    await this.client.login(this.config.token);
  }

  async stop() {
    console.log('[Bot] Shutting down...');
    this.client.destroy();
  }

  getClient() {
    return this.client;
  }

  getConfig() {
    return this.config;
  }
}

if (require.main === module) {
  const bot = new FactorifyBot();
  
  bot.start().catch(error => {
    console.error('[Bot] Failed to start:', error);
    process.exit(1);
  });

  process.on('SIGINT', async () => {
    console.log('[Bot] Received SIGINT signal');
    await bot.stop();
    process.exit(0);
  });

  process.on('SIGTERM', async () => {
    console.log('[Bot] Received SIGTERM signal');
    await bot.stop();
    process.exit(0);
  });
}

module.exports = FactorifyBot;
