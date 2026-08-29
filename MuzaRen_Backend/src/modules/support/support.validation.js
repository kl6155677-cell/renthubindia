const { z } = require('zod');

const createTicketSchema = z.object({
  subject: z.string().min(5, 'Subject must be at least 5 characters').max(100),
  message: z.string().min(20, 'Message must be at least 20 characters').max(2000)
});

module.exports = {
  createTicketSchema
};
