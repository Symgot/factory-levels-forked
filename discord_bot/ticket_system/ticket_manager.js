const { ChannelType, PermissionFlagsBits } = require('discord.js');
const fs = require('fs');
const path = require('path');

const TICKETS_FILE = path.join(__dirname, '../../data/tickets.json');
const TICKET_CATEGORY_NAME = 'Factorify Tickets';
const AUTO_CLOSE_DAYS = 7;

// TODO: For production, migrate to a proper database (MongoDB/PostgreSQL)
// JSON storage is suitable for development and small-scale deployments only
// Consider implementing a database abstraction layer for scalability

function ensureDataDirectory() {
  const dataDir = path.join(__dirname, '../../data');
  if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
  }
}

function loadTickets() {
  ensureDataDirectory();
  
  if (!fs.existsSync(TICKETS_FILE)) {
    return {};
  }

  try {
    const data = fs.readFileSync(TICKETS_FILE, 'utf8');
    return JSON.parse(data);
  } catch (error) {
    console.error('[TicketManager] Error loading tickets:', error);
    return {};
  }
}

function saveTickets(tickets) {
  ensureDataDirectory();
  
  try {
    fs.writeFileSync(TICKETS_FILE, JSON.stringify(tickets, null, 2), 'utf8');
  } catch (error) {
    console.error('[TicketManager] Error saving tickets:', error);
  }
}

async function createTicket(guild, user, fileData) {
  const ticketId = `ticket-${Date.now()}-${user.id.slice(-4)}`;
  
  let category = guild.channels.cache.find(
    c => c.name === TICKET_CATEGORY_NAME && c.type === ChannelType.GuildCategory
  );

  if (!category) {
    category = await guild.channels.create({
      name: TICKET_CATEGORY_NAME,
      type: ChannelType.GuildCategory
    });
  }

  const ticketChannel = await guild.channels.create({
    name: `${user.username}-${ticketId.split('-')[1].slice(-6)}`,
    type: ChannelType.GuildText,
    parent: category.id,
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
          PermissionFlagsBits.ReadMessageHistory,
          PermissionFlagsBits.AttachFiles
        ]
      },
      {
        id: guild.members.me.id,
        allow: [
          PermissionFlagsBits.ViewChannel,
          PermissionFlagsBits.SendMessages,
          PermissionFlagsBits.ManageChannels,
          PermissionFlagsBits.ReadMessageHistory
        ]
      }
    ]
  });

  const moderatorRole = guild.roles.cache.find(r => r.name.toLowerCase().includes('moderator'));
  if (moderatorRole) {
    await ticketChannel.permissionOverwrites.create(moderatorRole.id, {
      ViewChannel: true,
      SendMessages: true,
      ReadMessageHistory: true
    });
  }

  const ticket = {
    id: ticketId,
    userId: user.id,
    userName: user.username,
    guildId: guild.id,
    channelId: ticketChannel.id,
    fileName: fileData.name,
    fileUrl: fileData.url,
    fileSize: fileData.size,
    description: fileData.description || '',
    status: 'pending',
    createdAt: new Date().toISOString(),
    lastActivity: new Date().toISOString()
  };

  const tickets = loadTickets();
  tickets[ticketId] = ticket;
  saveTickets(tickets);

  await ticketChannel.send({
    content: `🎫 **Ticket Created** for ${user.toString()}`,
    embeds: [{
      title: '🔧 Factorio Mod Analysis',
      description: `**Ticket ID**: \`${ticketId}\`\n**File**: \`${fileData.name}\`\n**Size**: ${(fileData.size / 1024).toFixed(2)} KB`,
      fields: [
        { name: 'Status', value: '⏳ Pending', inline: true },
        { name: 'Created', value: `<t:${Math.floor(Date.now() / 1000)}:R>`, inline: true }
      ],
      color: 0xFFA500,
      timestamp: new Date(),
      footer: { text: 'This ticket will auto-close after 7 days of inactivity' }
    }]
  });

  console.log(`[TicketManager] Created ticket ${ticketId} for user ${user.tag}`);

  return {
    id: ticketId,
    channel: ticketChannel,
    data: ticket
  };
}

async function closeTicket(guild, ticketId) {
  const tickets = loadTickets();
  const ticket = tickets[ticketId];

  if (!ticket) {
    throw new Error('Ticket not found');
  }

  const channel = guild.channels.cache.get(ticket.channelId);
  if (channel) {
    await channel.send({
      embeds: [{
        title: '🔒 Ticket Closed',
        description: `Ticket \`${ticketId}\` has been closed.`,
        color: 0x808080,
        timestamp: new Date()
      }]
    });

    setTimeout(async () => {
      try {
        await channel.delete('Ticket closed');
      } catch (error) {
        console.error(`[TicketManager] Error deleting channel: ${error.message}`);
      }
    }, 5000);
  }

  ticket.status = 'closed';
  ticket.closedAt = new Date().toISOString();
  tickets[ticketId] = ticket;
  saveTickets(tickets);

  console.log(`[TicketManager] Closed ticket ${ticketId}`);
}

async function updateTicketStatus(ticketId, status, additionalData = {}) {
  const tickets = loadTickets();
  const ticket = tickets[ticketId];

  if (!ticket) {
    console.warn(`[TicketManager] Ticket not found: ${ticketId}`);
    return false;
  }

  ticket.status = status;
  ticket.lastActivity = new Date().toISOString();
  
  Object.assign(ticket, additionalData);

  tickets[ticketId] = ticket;
  saveTickets(tickets);

  console.log(`[TicketManager] Updated ticket ${ticketId} status to ${status}`);
  return true;
}

function getTicketStatus(ticketId) {
  const tickets = loadTickets();
  return tickets[ticketId] || null;
}

function listUserTickets(userId, guildId) {
  const tickets = loadTickets();
  return Object.values(tickets)
    .filter(t => t.userId === userId && t.guildId === guildId && t.status !== 'closed')
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
}

function listAllTickets(guildId) {
  const tickets = loadTickets();
  return Object.values(tickets)
    .filter(t => t.guildId === guildId)
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
}

async function cleanupInactiveTickets(guild) {
  const tickets = loadTickets();
  const now = new Date();
  let closedCount = 0;

  for (const [ticketId, ticket] of Object.entries(tickets)) {
    if (ticket.status === 'closed') continue;
    if (ticket.guildId !== guild.id) continue;

    const lastActivity = new Date(ticket.lastActivity);
    const daysSinceActivity = (now - lastActivity) / (1000 * 60 * 60 * 24);

    if (daysSinceActivity >= AUTO_CLOSE_DAYS) {
      try {
        await closeTicket(guild, ticketId);
        closedCount++;
      } catch (error) {
        console.error(`[TicketManager] Error closing inactive ticket ${ticketId}:`, error);
      }
    }
  }

  console.log(`[TicketManager] Cleaned up ${closedCount} inactive tickets`);
  return closedCount;
}

module.exports = {
  createTicket,
  closeTicket,
  updateTicketStatus,
  getTicketStatus,
  listUserTickets,
  listAllTickets,
  cleanupInactiveTickets
};
