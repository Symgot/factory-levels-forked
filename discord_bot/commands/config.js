const { SlashCommandBuilder, PermissionFlagsBits } = require('discord.js');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('config')
    .setDescription('Configure Factorify bot settings (Admin only)')
    .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
    .addSubcommand(subcommand =>
      subcommand
        .setName('view')
        .setDescription('View current bot configuration')
    )
    .addSubcommand(subcommand =>
      subcommand
        .setName('set-category')
        .setDescription('Set the category for ticket channels')
        .addStringOption(option =>
          option
            .setName('category-name')
            .setDescription('Name of the category (will be created if it doesn\'t exist)')
            .setRequired(true)
        )
    )
    .addSubcommand(subcommand =>
      subcommand
        .setName('set-webhook')
        .setDescription('Set Discord webhook URL for analysis results')
        .addStringOption(option =>
          option
            .setName('webhook-url')
            .setDescription('Discord webhook URL')
            .setRequired(true)
        )
    ),

  async execute(interaction, bot) {
    await interaction.deferReply({ ephemeral: true });

    try {
      const subcommand = interaction.options.getSubcommand();

      if (subcommand === 'view') {
        await interaction.editReply({
          content: '**Current Bot Configuration:**\n\n' +
                   `**Guild ID**: ${bot.config.guildId || 'Not set'}\n` +
                   `**GitHub Owner**: ${bot.config.githubOwner}\n` +
                   `**GitHub Repo**: ${bot.config.githubRepo}\n` +
                   `**Ticket Category**: Factorify Tickets\n` +
                   `**Auto-close after**: 7 days of inactivity`
        });
      } else if (subcommand === 'set-category') {
        const categoryName = interaction.options.getString('category-name');
        
        let category = interaction.guild.channels.cache.find(
          c => c.name === categoryName && c.type === 4
        );

        if (!category) {
          category = await interaction.guild.channels.create({
            name: categoryName,
            type: 4
          });
        }

        await interaction.editReply({
          content: `✅ Ticket category set to: **${categoryName}**\n` +
                   `Category ID: ${category.id}`
        });
      } else if (subcommand === 'set-webhook') {
        const webhookUrl = interaction.options.getString('webhook-url');
        
        if (!webhookUrl.startsWith('https://discord.com/api/webhooks/')) {
          await interaction.editReply({
            content: '❌ Invalid webhook URL. Must start with https://discord.com/api/webhooks/'
          });
          return;
        }

        // Note: This modifies process.env temporarily and will not persist across restarts
        // For production, use a proper configuration management system or environment files
        process.env.DISCORD_WEBHOOK_URL = webhookUrl;

        await interaction.editReply({
          content: '✅ Webhook URL configured successfully.\n\n' +
                   '⚠️ **Important**: This setting is temporary and will not persist after bot restart.\n' +
                   'Add `DISCORD_WEBHOOK_URL` to your environment variables for persistence.'
        });
      }
    } catch (error) {
      console.error('[Config] Command error:', error);
      await interaction.editReply({ content: `❌ An error occurred: ${error.message}` });
    }
  }
};
