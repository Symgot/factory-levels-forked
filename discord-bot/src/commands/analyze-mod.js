const { SlashCommandBuilder, ChannelType, PermissionFlagsBits } = require('discord.js');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('analyze-mod')
    .setDescription('Create a private ticket for mod analysis'),
  
  async execute(interaction) {
    await interaction.deferReply({ ephemeral: true });

    try {
      const guild = interaction.guild;
      const user = interaction.user;
      
      const existingTicket = guild.channels.cache.find(
        channel => channel.name === `ticket-${user.username}` && channel.type === ChannelType.GuildText
      );

      if (existingTicket) {
        await interaction.editReply({
          content: `You already have an active ticket: ${existingTicket}`,
          ephemeral: true
        });
        return;
      }

      const ticketChannel = await guild.channels.create({
        name: `ticket-${user.username}`,
        type: ChannelType.GuildText,
        parent: interaction.client.config?.discord?.ticketCategoryId,
        permissionOverwrites: [
          {
            id: guild.id,
            deny: [PermissionFlagsBits.ViewChannel]
          },
          {
            id: user.id,
            allow: [
              PermissionFlagsBits.ViewChannel,
              PermissionFlagsBits.SendMessages,
              PermissionFlagsBits.AttachFiles,
              PermissionFlagsBits.ReadMessageHistory
            ]
          }
        ]
      });

      interaction.client.tickets.set(ticketChannel.id, {
        userId: user.id,
        createdAt: Date.now()
      });

      await ticketChannel.send({
        content: `Welcome ${user}! 

**Factorify Mod Analysis Ticket**

Upload your mod files here:
• **Mod Archives (.zip)**: Full mod analysis including dependencies, compatibility, performance
• **Lua Files (.lua)**: Syntax validation, pattern detection, best practices check

**File Requirements:**
• Maximum size: 25MB
• Supported formats: .zip, .lua

The analysis will be processed automatically via GitHub Actions. Results will be posted here.

Type \`/close-ticket\` when you're done.`
      });

      await interaction.editReply({
        content: `Ticket created: ${ticketChannel}`,
        ephemeral: true
      });

    } catch (error) {
      console.error('Ticket creation error:', error);
      await interaction.editReply({
        content: 'Failed to create ticket. Please contact an administrator.',
        ephemeral: true
      });
    }
  }
};
