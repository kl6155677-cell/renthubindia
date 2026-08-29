const rateLimit = require('express-rate-limit');
const { RedisStore } = require('rate-limit-redis');
const redis = require('../config/redis');

// ── AUTH RATE LIMITER ───────────────────────────────────
// Protects auth pathways — caps per IP globally
const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // limit each IP to 10 auth requests per window
  standardHeaders: true, 
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many authentication requests from this IP, please try again after 15 minutes'
  },
  store: new RedisStore({
    sendCommand: (...args) => redis.call(...args),
    prefix: 'rl:auth:',
  }),
});

// ── OTP RATE LIMITER ────────────────────────────────────
// Even stricter for OTP endpoints (forgot-password, verify-otp, reset-password)
const otpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many OTP attempts. Please try again after 15 minutes.'
  },
  store: new RedisStore({
    sendCommand: (...args) => redis.call(...args),
    prefix: 'rl:otp:',
  }),
  keyGenerator: (req) => {
    const userIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';
    return `${userIp}:${req.body?.email || 'unknown'}`;
  },
});

// ── GENERAL API LIMITER ─────────────────────────────────
// Prevents API abuse across all endpoints
const apiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many requests. Please slow down.'
  },
  store: new RedisStore({
    sendCommand: (...args) => redis.call(...args),
    prefix: 'rl:api:',
  }),
  keyGenerator: (req) => {
    if (req.user?.id) return req.user.id;
    return req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';
  },
});

// ── UPLOAD LIMITER ──────────────────────────────────────
// Prevents excessive file uploads
const uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Upload limit reached. Please try again in an hour.'
  },
  store: new RedisStore({
    sendCommand: (...args) => redis.call(...args),
    prefix: 'rl:upload:',
  }),
  keyGenerator: (req) => {
    if (req.user?.id) return req.user.id;
    return req.headers['x-forwarded-for'] || req.socket.remoteAddress || 'unknown';
  },
});

// ── LISTING RATE LIMITER (existing — business logic) ────
// Per-user daily/monthly limits for unverified users
const listingRateLimiter = async (req, res, next) => {
  try {
    // TEMPORARILY DISABLED: Allow unlimited listings for all users until userbase grows.
    // To reactivate this rate limiter in the future, simply comment out or delete the line below.
    return next();

    // If user is verified, bypass rate limiting
    if (req.user && req.user.verificationStatus === 'VERIFIED') {
      return next();
    }

    const userId = req.user.id;
    const now = new Date();
    const today = now.toISOString().split('T')[0]; // YYYY-MM-DD
    const month = today.substring(0, 7); // YYYY-MM

    // In development, we bypass the rate limit checks
    if (process.env.NODE_ENV !== 'production') {
      return next();
    }

    const dailyKey = `rate_limit:listing:daily:${userId}:${today}`;
    const monthlyKey = `rate_limit:listing:monthly:${userId}:${month}`;

    const [dailyCount, monthlyCount] = await Promise.all([
      redis.get(dailyKey),
      redis.get(monthlyKey)
    ]);

    const dailyLimit = 2; // Maximum 2 listings per day
    const monthlyLimit = 5; // Maximum 5 listings per month

    if (parseInt(dailyCount || '0') >= dailyLimit) {
      return res.status(429).json({ 
        success: false, 
        message: 'Daily listing limit reached for unverified users. Max 2 listings per day.' 
      });
    }

    if (parseInt(monthlyCount || '0') >= monthlyLimit) {
      return res.status(429).json({ 
        success: false, 
        message: 'Monthly listing limit reached for unverified users. Max 5 listings per month.' 
      });
    }

    // Increment keys
    const multi = redis.multi()
      .incr(dailyKey)
      .incr(monthlyKey);

    // Set TTL if first time 
    if (!dailyCount) multi.expire(dailyKey, 86400); // 24 hours
    if (!monthlyCount) multi.expire(monthlyKey, 31 * 86400); // ~1 month

    await multi.exec();

    next();
  } catch (error) {
    console.error('Rate Limiter Error:', error);
    // Fail gracefully, allow request but log error
    next();
  }
};

module.exports = {
  authRateLimiter,
  otpLimiter,
  apiLimiter,
  uploadLimiter,
  listingRateLimiter
};
