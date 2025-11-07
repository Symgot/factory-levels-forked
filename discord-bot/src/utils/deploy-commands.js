const { REST, Routes } = require('discord.js');
const config = require('../config');
const commands = require('../commands');

const commandsData = commands.map(command => command.data.toJSON());

const rest = new REST({ version: '10' }).setToken(config.discord.token);

(async () => {
  try {
    console.log('Registering slash commands...');

    await rest.put(
      Routes.applicationGuildCommands(config.discord.clientId, config.discord.guildId),
      { body: commandsData }
    );

    console.log('Successfully registered slash commands.');
  } catch (error) {
    console.error('Error registering commands:', error);
  }
})();
