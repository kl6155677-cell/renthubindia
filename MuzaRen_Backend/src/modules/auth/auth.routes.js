const express = require('express');
const passport = require('passport');
const authController = require('./auth.controller');
const authMiddleware = require('../../middleware/auth');
const { 
  registerSchema, 
  loginSchema, 
  firebaseLoginSchema,
  forgotPasswordSchema, 
  verifyOtpSchema, 
  resetPasswordSchema, 
  refreshTokenSchema,
  validate 
} = require('./auth.validation');
const { authRateLimiter, otpLimiter } = require('../../middleware/rateLimit');

const router = express.Router();

router.use(authRateLimiter);

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, email, password]
 *             properties:
 *               name:
 *                 type: string
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       201:
 *         description: User registered successfully
 */
router.post('/register', validate(registerSchema), authController.register);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login user with email and password
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email:
 *                 type: string
 *               password:
 *                 type: string
 *     responses:
 *       200:
 *         description: Successful login with access and refresh tokens
 */
router.post('/login', validate(loginSchema), authController.login);

// Firebase Auth
/**
 * @swagger
 * /api/auth/firebase-login:
 *   post:
 *     summary: Login user with Firebase Phone Auth ID Token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [idToken]
 *             properties:
 *               idToken:
 *                 type: string
 *     responses:
 *       200:
 *         description: Successful login with access and refresh tokens
 */
router.post('/firebase-login', validate(firebaseLoginSchema), authController.firebaseLogin);

// Google OAuth
/**
 * @swagger
 * /api/auth/google:
 *   get:
 *     summary: Initiate Google OAuth2 consent screen
 *     tags: [Auth]
 *     responses:
 *       302:
 *         description: Redirect to Google login
 */
router.get('/google', passport.authenticate('google', { scope: ['profile', 'email'] }));

/**
 * @swagger
 * /api/auth/google/callback:
 *   get:
 *     summary: Google OAuth callback — returns JWT on success
 *     tags: [Auth]
 *     responses:
 *       200:
 *         description: JWT token returned
 */
router.get('/google/callback', passport.authenticate('google', { session: false, failureRedirect: '/login' }), authController.googleAuthCallback);

// Token refresh
/**
 * @swagger
 * /api/auth/refresh:
 *   post:
 *     summary: Refresh access token using a valid refresh token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [refreshToken]
 *             properties:
 *               refreshToken:
 *                 type: string
 *     responses:
 *       200:
 *         description: New access and refresh tokens issued
 */
router.post('/refresh', validate(refreshTokenSchema), authController.refresh);

// Reset password flows
/**
 * @swagger
 * /api/auth/forgot-password:
 *   post:
 *     summary: Send an OTP code to the user's email
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email]
 *             properties:
 *               email:
 *                 type: string
 *     responses:
 *       200:
 *         description: OTP sent via email
 */
router.post('/forgot-password', otpLimiter, validate(forgotPasswordSchema), authController.forgotPassword);

/**
 * @swagger
 * /api/auth/verify-otp:
 *   post:
 *     summary: Verify an OTP code
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, code]
 *             properties:
 *               email:
 *                 type: string
 *               code:
 *                 type: string
 *     responses:
 *       200:
 *         description: OTP valid
 */
router.post('/verify-otp', otpLimiter, validate(verifyOtpSchema), authController.verifyOtp);

/**
 * @swagger
 * /api/auth/reset-password:
 *   post:
 *     summary: Set a new password using the OTP code
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, code, newPassword]
 *             properties:
 *               email:
 *                 type: string
 *               code:
 *                 type: string
 *               newPassword:
 *                 type: string
 *     responses:
 *       200:
 *         description: Password updated
 */
router.post('/reset-password', otpLimiter, validate(resetPasswordSchema), authController.resetPassword);

// Secured logout
/**
 * @swagger
 * /api/auth/logout:
 *   post:
 *     summary: Invalidate current JWT and end session
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Session terminated
 */
router.post('/logout', authMiddleware, authController.logout);

module.exports = router;
