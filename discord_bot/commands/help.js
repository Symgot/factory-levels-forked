const { SlashCommandBuilder, EmbedBuilder } = require('discord.js');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('help')
    .setDescription('Get help with Factorify bot commands'),

  async execute(interaction, bot) {
    const helpEmbed = new EmbedBuilder()
      .setTitle('🤖 Factorify Bot Help')
      .setDescription('Analyze Factorio mods with GitHub Actions integration')
      .setColor(0x0099FF)
      .addFields([
        {
          name: '📤 /analyze',
          value: 'Upload and analyze a Factorio mod\n' +
                 '**Usage**: `/analyze file:<attachment> [description:<text>]`\n' +
                 '**Accepted files**: .lua, .zip, .tar.gz (max 10 MB)\n' +
                 '**Example**: `/analyze file:my-mod.zip description:"My awesome mod"`',
          inline: false
        },
        {
          name: '📊 /status',
          value: 'Check the status of your analysis tickets\n' +
                 '**Usage**: `/status [ticket-id:<id>]`\n' +
                 '**Example**: `/status` or `/status ticket-id:ticket-123456`',
          inline: false
        },
        {
          name: '❓ /help',
          value: 'Display this help message\n' +
                 '**Usage**: `/help`',
          inline: false
        },
        {
          name: '⚙️ /config',
          value: 'Configure bot settings (Admin only)\n' +
                 '**Usage**: `/config <option> <value>`',
          inline: false
        }
      ])
      .addFields([
        {
          name: '📋 How it works',
          value: '1. Upload your mod file using `/analyze`\n' +
                 '2. A private ticket channel is created for you\n' +
                 '3. The bot triggers GitHub Actions workflow\n' +
                 '4. Analysis results are posted in your ticket\n' +
                 '5. Ticket auto-closes after 7 days of inactivity',
          inline: false
        },
        {
          name: '🔍 Analysis Features',
          value: '• ML-based pattern recognition\n' +
                 '• Performance optimization suggestions\n' +
                 '• Obfuscation detection\n' +
                 '• Security vulnerability scanning\n' +
                 '• API compatibility checking',
          inline: false
        },
        {
          name: '🎫 Ticket System',
          value: '• Private channels per user\n' +
                 '• Real-time status updates\n' +
                 '• Detailed error reporting\n' +
                 '• Automatic cleanup\n' +
                 '• History preservation',
          inline: false
        }
      ])
      .setFooter({ text: 'Powered by GitHub Actions & Discord.js v14' })
      .setTimestamp();

    await interaction.reply({ embeds: [helpEmbed], ephemeral: true });
  }
};
