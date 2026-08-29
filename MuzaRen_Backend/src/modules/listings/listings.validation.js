const { z } = require('zod');

const createListingSchema = z.object({
  categoryId: z.string().uuid('Invalid Category ID'),
  title: z.string().min(5, 'Title must be at least 5 characters').max(100),
  description: z.string().min(20, 'Description must be at least 20 characters'),
  pricePerDay: z.number().positive('Price must be positive'),
  location: z.string().min(3, 'Location is required'),
  latitude: z.number().optional(),
  longitude: z.number().optional(),
  country: z.string().optional(),
  city: z.string().optional(),
  availableFrom: z.string().datetime().optional(),
  availableTo: z.string().datetime().optional()
});

const updateListingSchema = createListingSchema.partial().omit({ categoryId: true });

const updateStatusSchema = z.object({
  status: z.enum(['ACTIVE', 'PAUSED'])
});

const browseSchema = z.object({
  userId: z.string().uuid().optional(),
  category: z.string().optional(),
  country: z.string().optional(),
  city: z.string().optional(),
  search: z.string().optional(),
  priceMin: z.coerce.number().optional(),
  priceMax: z.coerce.number().optional(),
  sortBy: z.enum(['newest', 'price_asc', 'price_desc', 'rating']).optional().default('newest'),
  page: z.coerce.number().optional().default(1),
  limit: z.coerce.number().optional().default(20)
});

module.exports = {
  createListingSchema,
  updateListingSchema,
  updateStatusSchema,
  browseSchema
};
