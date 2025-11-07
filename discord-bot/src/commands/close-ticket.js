const { SlashCommandBuilder } = require('discord.js');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('close-ticket')
    .setDescription('Close your current ticket'),
  
  async execute(interaction) {
    const ticket = interaction.client.tickets.get(interaction.channel.id);
    
    if (!ticket) {
      await interaction.reply({
        content: 'This is not a ticket channel.',
        ephemeral: true
      });
      return;
    }

    if (ticket.userId !== interaction.user.id) {
      await interaction.reply({
        content: 'You can only close your own tickets.',
        ephemeral: true
      });
      return;
    }

    await interaction.reply('Closing ticket in 5 seconds...');
    
    setTimeout(async () => {
      interaction.client.tickets.delete(interaction.channel.id);
      await interaction.channel.delete();
    }, 5000);
  }
};
