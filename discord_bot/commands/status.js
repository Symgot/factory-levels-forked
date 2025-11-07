const { SlashCommandBuilder, EmbedBuilder } = require('discord.js');
const { getTicketStatus, listUserTickets } = require('../ticket_system/ticket_manager');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('status')
    .setDescription('Check the status of your analysis tickets')
    .addStringOption(option =>
      option
        .setName('ticket-id')
        .setDescription('Specific ticket ID to check (leave empty for all your tickets)')
        .setRequired(false)
    ),

  async execute(interaction, bot) {
    await interaction.deferReply({ ephemeral: true });

    try {
      const ticketId = interaction.options.getString('ticket-id');

      if (ticketId) {
        const status = await getTicketStatus(ticketId);

        if (!status) {
          await interaction.editReply({ content: `❌ Ticket not found: ${ticketId}` });
          return;
        }

        if (status.userId !== interaction.user.id) {
          await interaction.editReply({ content: '❌ You do not have permission to view this ticket.' });
          return;
        }

        const statusEmbed = new EmbedBuilder()
          .setTitle(`🎫 Ticket Status: ${ticketId}`)
          .setDescription(status.description || 'No description')
          .addFields([
            { name: 'Status', value: getStatusEmoji(status.status) + ' ' + status.status.toUpperCase(), inline: true },
            { name: 'File Name', value: status.fileName || 'N/A', inline: true },
            { name: 'Created', value: `<t:${Math.floor(new Date(status.createdAt).getTime() / 1000)}:R>`, inline: true }
          ])
          .setColor(getStatusColor(status.status))
          .setTimestamp();

        if (status.channelId) {
          statusEmbed.addFields({
            name: 'Channel',
            value: `<#${status.channelId}>`,
            inline: true
          });
        }

        if (status.results) {
          statusEmbed.addFields({
            name: 'Results',
            value: `✅ ${status.results.passed || 0} passed\n❌ ${status.results.failed || 0} failed`,
            inline: true
          });
        }

        await interaction.editReply({ embeds: [statusEmbed] });
      } else {
        const userTickets = await listUserTickets(interaction.user.id, interaction.guild.id);

        if (userTickets.length === 0) {
          await interaction.editReply({ content: '📭 You have no analysis tickets.' });
          return;
        }

        const ticketsEmbed = new EmbedBuilder()
          .setTitle('📋 Your Analysis Tickets')
          .setDescription(`You have ${userTickets.length} ticket(s)`)
          .setColor(0x0099FF)
          .setTimestamp();

        for (const ticket of userTickets.slice(0, 10)) {
          const statusLine = `${getStatusEmoji(ticket.status)} **${ticket.status.toUpperCase()}**`;
          const timeLine = `Created <t:${Math.floor(new Date(ticket.createdAt).getTime() / 1000)}:R>`;
          const channelLine = ticket.channelId ? `<#${ticket.channelId}>` : 'Channel deleted';

          ticketsEmbed.addFields({
            name: `${ticket.id}`,
            value: `${statusLine}\n${ticket.fileName || 'N/A'}\n${timeLine}\n${channelLine}`,
            inline: true
          });
        }

        if (userTickets.length > 10) {
          ticketsEmbed.setFooter({ text: `Showing 10 of ${userTickets.length} tickets` });
        }

        await interaction.editReply({ embeds: [ticketsEmbed] });
      }
    } catch (error) {
      console.error('[Status] Command error:', error);
      await interaction.editReply({ content: `❌ An error occurred: ${error.message}` });
    }
  }
};

function getStatusEmoji(status) {
  const emojis = {
    pending: '⏳',
    analyzing: '🔄',
    completed: '✅',
    failed: '❌',
    cancelled: '🚫'
  };
  return emojis[status] || '❓';
}

function getStatusColor(status) {
  const colors = {
    pending: 0xFFA500,
    analyzing: 0x0099FF,
    completed: 0x00FF00,
    failed: 0xFF0000,
    cancelled: 0x808080
  };
  return colors[status] || 0x808080;
}
