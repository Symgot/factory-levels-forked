const { SlashCommandBuilder, AttachmentBuilder } = require('discord.js');
const { createTicket } = require('../ticket_system/ticket_manager');
const { triggerAnalysis } = require('../github_integration/workflow_trigger');
const { extractFiles } = require('../file_handler/upload_handler');

module.exports = {
  data: new SlashCommandBuilder()
    .setName('analyze')
    .setDescription('Upload and analyze a Factorio mod')
    .addAttachmentOption(option =>
      option
        .setName('file')
        .setDescription('Mod archive (.zip, .tar.gz) or Lua file')
        .setRequired(true)
    )
    .addStringOption(option =>
      option
        .setName('description')
        .setDescription('Optional description or notes about the mod')
        .setRequired(false)
    ),

  async execute(interaction, bot) {
    await interaction.deferReply({ ephemeral: true });

    try {
      const file = interaction.options.getAttachment('file');
      const description = interaction.options.getString('description') || 'No description provided';

      if (!file) {
        await interaction.editReply({ content: '❌ No file provided.' });
        return;
      }

      const allowedExtensions = ['.lua', '.zip', '.tar.gz', '.tar', '.gz'];
      const fileName = file.name.toLowerCase();
      const isValidFile = allowedExtensions.some(ext => fileName.endsWith(ext));

      if (!isValidFile) {
        await interaction.editReply({
          content: `❌ Invalid file type. Allowed types: ${allowedExtensions.join(', ')}`
        });
        return;
      }

      if (file.size > 10 * 1024 * 1024) {
        await interaction.editReply({
          content: '❌ File too large. Maximum size: 10 MB'
        });
        return;
      }

      console.log(`[Analyze] Processing file: ${file.name} (${file.size} bytes) from ${interaction.user.tag}`);

      const ticket = await createTicket(
        interaction.guild,
        interaction.user,
        {
          name: file.name,
          url: file.url,
          size: file.size,
          description: description
        }
      );

      await interaction.editReply({
        content: `✅ Analysis ticket created: ${ticket.channel.toString()}\n\n` +
                 `File: \`${file.name}\`\n` +
                 `Size: ${(file.size / 1024).toFixed(2)} KB\n\n` +
                 `Your mod is being analyzed. You'll receive updates in the ticket channel.`
      });

      await ticket.channel.send({
        embeds: [{
          title: '⏳ Analysis Started',
          description: `Analyzing mod file: \`${file.name}\``,
          fields: [
            { name: 'File Size', value: `${(file.size / 1024).toFixed(2)} KB`, inline: true },
            { name: 'Submitted By', value: interaction.user.toString(), inline: true },
            { name: 'Status', value: '🔄 Downloading file...', inline: false }
          ],
          color: 0xFFA500,
          timestamp: new Date()
        }]
      });

      try {
        const fileData = await extractFiles(file);
        
        await ticket.channel.send({
          embeds: [{
            title: '📦 File Extracted',
            description: `Found ${fileData.files.length} file(s) in the archive`,
            fields: fileData.files.map(f => ({
              name: f.name,
              value: `${(f.size / 1024).toFixed(2)} KB`,
              inline: true
            })).slice(0, 10),
            color: 0x00FF00,
            timestamp: new Date()
          }]
        });

        const analysisResult = await triggerAnalysis(
          ticket.id,
          fileData,
          {
            githubToken: bot.config.githubToken,
            owner: bot.config.githubOwner,
            repo: bot.config.githubRepo,
            webhookUrl: process.env.DISCORD_WEBHOOK_URL
          }
        );

        if (analysisResult.success) {
          await ticket.channel.send({
            embeds: [{
              title: '🚀 GitHub Actions Triggered',
              description: 'Your mod is now being analyzed on GitHub Actions',
              fields: [
                { name: 'Workflow Run ID', value: `${analysisResult.runId || 'Pending'}`, inline: true },
                { name: 'Status', value: '⏳ Running...', inline: true }
              ],
              color: 0x0099FF,
              timestamp: new Date(),
              footer: { text: 'You will be notified when the analysis is complete' }
            }]
          });
        } else {
          throw new Error(analysisResult.error || 'Failed to trigger analysis');
        }
      } catch (error) {
        console.error('[Analyze] Error processing file:', error);
        await ticket.channel.send({
          embeds: [{
            title: '❌ Analysis Failed',
            description: `Failed to process file: ${error.message}`,
            color: 0xFF0000,
            timestamp: new Date()
          }]
        });
      }
    } catch (error) {
      console.error('[Analyze] Command error:', error);
      await interaction.editReply({
        content: `❌ An error occurred: ${error.message}`
      });
    }
  }
};
