const { z } = require('zod');

const updateProfileSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').optional(),
  phone: z.string().min(8, 'Phone number must be at least 8 characters').optional().nullable(),
  city: z.string().optional().nullable(),
  country: z.string().optional().nullable(),
  currency: z.string().optional().nullable(),
  avatarUrl: z.string().optional().nullable(),
});

const changePasswordSchema = z.object({
  oldPassword: z.string().min(1, 'Old password is required'),
  newPassword: z.string().min(8, 'New password must be at least 8 characters'),
});

const fcmTokenSchema = z.object({
  fcmToken: z.string().min(1, 'Token is required')
});

module.exports = {
  updateProfileSchema,
  changePasswordSchema,
  fcmTokenSchema
};
