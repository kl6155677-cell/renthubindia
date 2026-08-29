const { z } = require('zod');

const submitReviewSchema = z.object({
  bookingId: z.string().uuid('Invalid Booking ID'),
  rating: z.number().int('Rating must be an integer').min(1, 'Rating must be at least 1').max(5, 'Rating cannot exceed 5'),
  comment: z.string().max(500, 'Comment cannot exceed 500 characters').optional()
});

const paginationSchema = z.object({
  page: z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(10)
});

module.exports = {
  submitReviewSchema,
  paginationSchema
};
