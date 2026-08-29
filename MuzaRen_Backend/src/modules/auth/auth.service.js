const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const prisma = require('../../config/db');
const redis = require('../../config/redis');
const { generateAccessToken, generateRefreshToken, verifyRefreshToken } = require('../../utils/jwt');
const otpUtils = require('../../utils/otp');
const mailer = require('../../utils/mailer');
const geoip = require('geoip-lite');
const currencyMap = require('../../utils/currency');
const SecurityLogger = require('../../utils/securityLogger');
const { firebaseAdmin } = require('../../config/firebase');

// ─── HELPERS ────────────────────────────────────────────

/**
 * Strip sensitive fields from user object before sending to client.
 * NEVER return passwordHash, googleId, fcmToken, or verificationDoc.
 */
const sanitizeUser = (user) => {
  const { passwordHash, googleId, fcmToken, verificationDoc, ...safeUser } = user;
  return safeUser;
};

/**
 * Generate access + refresh token pair and store refresh token hash in Redis.
 */
const generateTokenPair = async (user) => {
  const payload = { id: user.id, role: user.role };
  const accessToken  = generateAccessToken(payload);
  const refreshToken = generateRefreshToken(payload);

  // Store refresh token hash in Redis for validation and rotation
  // Key pattern: refresh:{userId}:{tokenHash} — allows multiple devices
  const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
  await redis.setex(
    `refresh:${user.id}:${tokenHash}`,
    30 * 24 * 60 * 60, // 30 days in seconds
    'valid'
  );

  return { accessToken, refreshToken, expiresIn: 15 * 60 }; // 15 minutes in seconds
};

// ─── AUTH FUNCTIONS ─────────────────────────────────────

const register = async (data, ip) => {
  const { name, password } = data;
  const email = data.email.toLowerCase();

  const existingUser = await prisma.user.findUnique({ where: { email } });
  if (existingUser) throw new Error('User already exists');

  const salt = await bcrypt.genSalt(12);
  const passwordHash = await bcrypt.hash(password, salt);

  // GeoIP detection with robust IP handling
  // If IP is a comma-separated list (from proxies), take the first one
  const clientIp = ip ? ip.split(',')[0].trim() : ip;
  const geo = geoip.lookup(clientIp);
  
  const country = geo ? geo.country : (data.country || null);
  const city = geo ? geo.city : (data.city || null);
  const currency = currencyMap.getCurrencyFromCountry(country) || 'USD';

  const user = await prisma.user.create({
    data: { name, email, passwordHash, country, city, currency }
  });

  const tokens = await generateTokenPair(user);

  return {
    user: sanitizeUser(user),
    ...tokens,
  };
};

const login = async (emailRaw, password, ip) => {
  const email = emailRaw.toLowerCase();

  // ── BRUTE FORCE PROTECTION ────────────────────────────
  const MAX_ATTEMPTS = 10;
  const LOCKOUT_DURATION = 15 * 60; // 15 minutes in seconds
  const attemptsKey = `login_attempts:${email}`;
  const lockoutKey  = `login_lockout:${email}`;

  // Check if account is locked out
  const isLockedOut = await redis.get(lockoutKey);
  if (isLockedOut) {
    const ttl = await redis.ttl(lockoutKey);
    throw new Error(`Too many failed attempts. Try again in ${Math.ceil(ttl / 60)} minutes.`);
  }

  const user = await prisma.user.findUnique({ where: { email } });

  // Wrong email or wrong password — same error message (prevent user enumeration)
  if (!user || !user.passwordHash) {
    // Increment failed attempts even for non-existent users
    const attempts = await redis.incr(attemptsKey);
    if (attempts === 1) await redis.expire(attemptsKey, LOCKOUT_DURATION);
    if (attempts >= MAX_ATTEMPTS) {
      await redis.setex(lockoutKey, LOCKOUT_DURATION, 'locked');
      await redis.del(attemptsKey);
      SecurityLogger.accountLocked(email, ip);
    }
    SecurityLogger.loginFailed(email, ip, attempts);
    throw new Error('Invalid email or password');
  }

  const isMatch = await bcrypt.compare(password, user.passwordHash);
  if (!isMatch) {
    const attempts = await redis.incr(attemptsKey);
    if (attempts === 1) await redis.expire(attemptsKey, LOCKOUT_DURATION);
    if (attempts >= MAX_ATTEMPTS) {
      await redis.setex(lockoutKey, LOCKOUT_DURATION, 'locked');
      await redis.del(attemptsKey);
      SecurityLogger.accountLocked(email, ip);
    }
    SecurityLogger.loginFailed(email, ip, attempts);
    throw new Error('Invalid email or password');
  }

  if (user.isBlocked) throw new Error('Your account has been blocked. Contact support.');

  // Success — clear failed attempts
  await redis.del(attemptsKey);
  SecurityLogger.loginSuccess(user.id, ip);

  const tokens = await generateTokenPair(user);

  return {
    user: sanitizeUser(user),
    ...tokens,
  };
};

const firebaseLogin = async (idToken, ip) => {
  if (!firebaseAdmin) {
    throw new Error('Firebase Admin SDK is not configured');
  }

  try {
    const decodedToken = await firebaseAdmin.auth().verifyIdToken(idToken);
    const phone = decodedToken.phone_number;

    if (!phone) {
      throw new Error('No phone number attached to this Firebase credential');
    }

    let user = await prisma.user.findUnique({ where: { phone } });

    if (user) {
      if (user.isBlocked) throw new Error('Your account has been blocked. Contact support.');
    } else {
      const geo = geoip.lookup(ip);
      const country = geo ? geo.country : null;
      const city = geo ? geo.city : null;
      const currency = currencyMap.getCurrencyFromCountry(country) || 'USD';

      user = await prisma.user.create({
        data: { 
          name: 'New User', // Default name, they can change it later in profile
          phone, 
          country, 
          city, 
          currency, 
          verificationStatus: 'UNVERIFIED',
          role: 'USER'
        }
      });
    }

    SecurityLogger.loginSuccess(user.id, ip);
    const tokens = await generateTokenPair(user);

    return {
      user: sanitizeUser(user),
      ...tokens,
    };
  } catch (error) {
    throw new Error(`Firebase Auth Error: ${error.message}`);
  }
};

const googleLogin = async (profile, ip) => {
  const email = profile.emails[0].value.toLowerCase();
  const name = profile.displayName;
  const googleId = profile.id;
  const avatarUrl = profile.photos && profile.photos.length > 0 ? profile.photos[0].value : null;

  let user = await prisma.user.findUnique({ where: { email } });

  if (user) {
    if (user.isBlocked) throw new Error('Your account has been blocked. Contact support.');
    if (!user.googleId) {
      user = await prisma.user.update({
        where: { id: user.id },
        data: { googleId, avatarUrl: user.avatarUrl || avatarUrl }
      });
    }
  } else {
    const geo = geoip.lookup(ip);
    const country = geo ? geo.country : null;
    const city = geo ? geo.city : null;
    const currency = currencyMap.getCurrencyFromCountry(country);

    user = await prisma.user.create({
      data: { name, email, googleId, avatarUrl, country, city, currency, verificationStatus: 'UNVERIFIED' }
    });
  }

  SecurityLogger.loginSuccess(user.id, ip);
  const tokens = await generateTokenPair(user);

  return {
    user: sanitizeUser(user),
    ...tokens,
  };
};

const forgotPassword = async (emailRaw) => {
  const email = emailRaw.toLowerCase();
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) throw new Error('User not found');
  if (!user.passwordHash) throw new Error('OAuth accounts cannot utilize forgotten password flows.');

  const code = await otpUtils.generateOTP(user.id);
  await mailer.sendOtpEmail(email, code);
  return { message: 'OTP sent successfully to email address' };
};

const verifyOtp = async (emailRaw, code) => {
  const email = emailRaw.toLowerCase();
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) throw new Error('User not found');

  // We set markUsed to false so the reset flow can actually consume it
  const isValid = await otpUtils.verifyOTP(user.id, code, false);
  if (!isValid) throw new Error('Invalid or expired OTP code');

  return { message: 'OTP successfully verified' };
};

const resetPassword = async (emailRaw, code, newPassword) => {
  const email = emailRaw.toLowerCase();
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) throw new Error('User not found');

  // This step actually consumes the OTP preventing reuse
  const isValid = await otpUtils.verifyOTP(user.id, code, true);
  if (!isValid) throw new Error('Invalid or expired OTP code');

  const salt = await bcrypt.genSalt(12);
  const passwordHash = await bcrypt.hash(newPassword, salt);

  await prisma.user.update({
    where: { id: user.id },
    data: { passwordHash }
  });

  // Invalidate ALL refresh tokens for this user (force re-login on all devices)
  const keys = await redis.keys(`refresh:${user.id}:*`);
  if (keys.length > 0) await redis.del(...keys);

  SecurityLogger.tokenRevoked(user.id, 'password_reset');

  return { message: 'Password has been successfully reset' };
};

const refreshTokens = async (refreshToken) => {
  if (!refreshToken) throw new Error('Refresh token required');

  // Verify the refresh token signature
  let decoded;
  try {
    decoded = verifyRefreshToken(refreshToken);
  } catch (err) {
    throw new Error('Invalid or expired refresh token');
  }

  // Check if refresh token exists in Redis (not rotated/logged out)
  const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
  const isValid = await redis.get(`refresh:${decoded.id}:${tokenHash}`);

  if (!isValid) {
    // Token was already used or user logged out — possible theft
    // Invalidate ALL refresh tokens for this user (security measure)
    const keys = await redis.keys(`refresh:${decoded.id}:*`);
    if (keys.length > 0) await redis.del(...keys);
    SecurityLogger.suspiciousActivity('Refresh token reuse detected', { userId: decoded.id });
    throw new Error('Refresh token revoked — please log in again');
  }

  // Rotate: invalidate old refresh token
  await redis.del(`refresh:${decoded.id}:${tokenHash}`);

  // Check user still exists and is not blocked
  const user = await prisma.user.findUnique({
    where: { id: decoded.id },
    select: { id: true, role: true, isBlocked: true }
  });

  if (!user) throw new Error('User not found');
  if (user.isBlocked) throw new Error('Your account has been blocked. Contact support.');

  // Issue new token pair
  const tokens = await generateTokenPair(user);
  return tokens;
};

const logout = async (userId, accessToken, refreshToken) => {
  // Blacklist access token in Redis (so it can't be used until it expires)
  if (accessToken) {
    try {
      const jwt = require('jsonwebtoken');
      const decoded = jwt.decode(accessToken);
      if (decoded && decoded.exp) {
        const ttl = decoded.exp - Math.floor(Date.now() / 1000);
        if (ttl > 0) {
          await redis.setex(`blacklist:${accessToken}`, ttl, 'revoked');
        }
      }
    } catch (error) {
      // Ignore decode errors — token might already be expired
    }
  }

  // Revoke refresh token
  if (refreshToken) {
    const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
    await redis.del(`refresh:${userId}:${tokenHash}`);
  }

  SecurityLogger.tokenRevoked(userId, 'logout');
};

module.exports = {
  register, login, firebaseLogin, googleLogin, forgotPassword, verifyOtp, resetPassword, refreshTokens, logout
};
