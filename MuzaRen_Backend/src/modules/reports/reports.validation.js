const { z } = require('zod');

const submitReportSchema = z.object({
  targetType: z.enum(['LISTING', 'USER', 'MESSAGE']),
  targetId: z.string().uuid('Invalid Target ID'),
  category: z.enum(['FRAUD', 'SPAM', 'ABUSE', 'FAKE_LISTING']),
  description: z.string().min(10, 'Description must be at least 10 characters').max(1000).optional()
});

module.exports = {
  submitReportSchema
};
