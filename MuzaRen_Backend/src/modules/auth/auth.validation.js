const { z } = require('zod');

// ── Strong password policy ──────────────────────────────
const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
  .regex(/[0-9]/, 'Password must contain at least one number')
  .regex(/[^A-Za-z0-9]/, 'Password must contain at least one special character');

const registerSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters').max(100).trim(),
  email: z.string().email('Invalid email address').toLowerCase().trim(),
  password: passwordSchema,
});

const loginSchema = z.object({
  email: z.string().email('Invalid email address').toLowerCase().trim(),
  password: z.string().min(1, 'Password is required'),
});

const firebaseLoginSchema = z.object({
  idToken: z.string().min(1, 'Firebase ID Token is required'),
});

const forgotPasswordSchema = z.object({
  email: z.string().email('Invalid email address').toLowerCase().trim(),
});

const verifyOtpSchema = z.object({
  email: z.string().email('Invalid email address').toLowerCase().trim(),
  code: z.string().length(6, 'OTP must be exactly 6 digits').regex(/^\d{6}$/, 'OTP must be 6 digits'),
});

const resetPasswordSchema = z.object({
  email: z.string().email('Invalid email address').toLowerCase().trim(),
  code: z.string().length(6, 'OTP must be exactly 6 digits').regex(/^\d{6}$/),
  newPassword: passwordSchema,
});

const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
});

// Middleware for validation
const validate = (schema) => (req, res, next) => {
  try {
    schema.parse(req.body);
    next();
  } catch (error) {
    next(error); // Triggers ZodError block in errorHandler.js
  }
};

module.exports = {
  registerSchema,
  loginSchema,
  firebaseLoginSchema,
  forgotPasswordSchema,
  verifyOtpSchema,
  resetPasswordSchema,
  refreshTokenSchema,
  validate
};
