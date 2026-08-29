const { z } = require('zod');

// ── Utility: auto-generate a URL-friendly slug from a name string ──
const toSlug = (name) =>
  name.toLowerCase().trim().replace(/[\s_]+/g, '-').replace(/[^a-z0-9-]/g, '').replace(/-+/g, '-');

const actionReportSchema = z.object({
  status: z.enum(['REVIEWED', 'RESOLVED']),
  // adminNote is optional — admin may act without a note (e.g. quick REVIEWED mark)
  adminNote: z.string().min(1).max(500).optional(),
});

const replyTicketSchema = z.object({
  // Lowered from 10 to 2 — short replies like "Fixed." are valid admin responses
  adminReply: z.string().min(2).max(2000),
});

const createCategorySchema = z.object({
  name: z.string().min(2).max(50),
  description: z.string().max(200).optional(),
  icon: z.string().max(100).optional(),
  // slug is optional — auto-generated from name if not provided
  slug: z.string().min(2).max(50).regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, 'Slug must be url-friendly lowercase').optional(),
});

const updateCategorySchema = createCategorySchema.partial();

const paginationSchema = z.object({
  page:  z.coerce.number().int().min(1).optional().default(1),
  limit: z.coerce.number().int().min(1).max(100).optional().default(20),
});

module.exports = {
  actionReportSchema,
  replyTicketSchema,
  createCategorySchema,
  updateCategorySchema,
  paginationSchema,
  toSlug,
};
