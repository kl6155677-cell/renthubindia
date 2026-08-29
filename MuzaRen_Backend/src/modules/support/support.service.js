const prisma = require('../../config/db');

const createTicket = async (userId, data) => {
  const { subject, message } = data;

  const ticket = await prisma.supportTicket.create({
    data: {
      userId,
      subject,
      message,
      status: 'OPEN' // Requires Admin oversight to close
    }
  });

  return ticket;
};

const { paginate } = require('../../utils/paginate');

const getMyTickets = async (userId, { status, page, limit }) => {
  const where = { userId };
  if (status) where.status = status;

  return paginate({
    modelName: 'supportTicket',
    where,
    orderBy: { createdAt: 'desc' },
    page,
    limit,
  });
};

const getTicketById = async (userId, ticketId) => {
  const ticket = await prisma.supportTicket.findUnique({
    where: { id: ticketId }
  });

  if (!ticket) throw new Error('Ticket not found');
  if (ticket.userId !== userId) throw new Error('Unauthorized');

  return ticket;
};

module.exports = {
  createTicket,
  getMyTickets,
  getTicketById
};
