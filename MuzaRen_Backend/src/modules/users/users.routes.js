const express = require('express');
const usersController = require('./users.controller');
const authMiddleware = require('../../middleware/auth');
const { requireAdmin } = require('../../middleware/role');
const { validate } = require('../auth/auth.validation'); 
const { updateProfileSchema, changePasswordSchema, fcmTokenSchema } = require('./users.validation');
const { avatarUpload, documentUpload } = require('../../config/cloudinary');

const router = express.Router();

// Apply auth strictly to all user routes downstream
router.use(authMiddleware); 

/**
 * @swagger
 * /api/users/profile:
 *   get:
 *     summary: Get current logged in user profile
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *   put:
 *     summary: Update profile details
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.get('/profile', usersController.getProfile);
router.put('/profile', validate(updateProfileSchema), usersController.updateProfile);
router.post('/profile/change-password', validate(changePasswordSchema), usersController.changePassword);

/**
 * @swagger
 * /api/users/avatar:
 *   post:
 *     summary: Upload new profile avatar directly to Cloudinary
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.post('/avatar', avatarUpload, usersController.uploadAvatar);

/**
 * @swagger
 * /api/users/fcm-token:
 *   post:
 *     summary: Bind physical device token for Push Notifications
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.post('/fcm-token', validate(fcmTokenSchema), usersController.updateFCMToken);

// Admin-only paths
/**
 * @swagger
 * /api/users:
 *   get:
 *     summary: Retrieve universal tracking of all users (Admin)
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.get('/', requireAdmin, usersController.getAllUsers);

/**
 * @swagger
 * /api/users/{id}/block:
 *   patch:
 *     summary: Circuit breaks a user mapping locally (Admin)
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.patch('/:id/block', requireAdmin, usersController.blockUser);

// Verification and Profile specific
/**
 * @swagger
 * /api/users/me/verify:
 *   post:
 *     summary: Upload KYC documents triggering manual review
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 */
router.post('/me/verify', documentUpload, usersController.submitVerification);

/**
 * @swagger
 * /api/users/{id}:
 *   get:
 *     summary: Inspect public bounds of User Profile dynamically
 *     tags: [Users]
 */
router.get('/:id', usersController.getPublicProfile);

module.exports = router;
