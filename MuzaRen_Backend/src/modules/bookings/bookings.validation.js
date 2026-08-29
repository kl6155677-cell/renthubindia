const { z } = require('zod');

const createBookingSchema = z.object({
  listingId: z.string().uuid('Invalid Listing ID'),
  startDate: z.string().datetime({ message: 'Start date must be an ISO datetime string' }),
  endDate: z.string().datetime({ message: 'End date must be an ISO datetime string' }),
  notes: z.string().max(500, 'Notes cannot exceed 500 characters').optional()
}).refine(data => new Date(data.startDate) < new Date(data.endDate), {
  message: 'End date must be strictly after start date',
  path: ['endDate']
}).refine(data => {
  const start = new Date(data.startDate);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  // Allow dates that are today or in the future
  return start >= today || start.toDateString() === today.toDateString();
}, {
  message: 'Start date cannot be in the past',
  path: ['startDate']
});

module.exports = {
  createBookingSchema
};
