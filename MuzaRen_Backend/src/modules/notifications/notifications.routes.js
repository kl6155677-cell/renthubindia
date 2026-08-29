const express = require('express');
const notificationsController = require('./notifications.controller');
const authMiddleware = require('../../middleware/auth');

const router = express.Router();

// The entire Notification mapping must be secured behind JWT bounds 
router.use(authMiddleware);

/**
 * @swagger
 * /api/notifications:
 *   get:
 *     summary: Fetch current array mapped notifications securely
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Notifications structurally delivered
 */
router.get('/', notificationsController.getUserNotifications);

/**
 * @swagger
 * /api/notifications/read-all:
 *   patch:
 *     summary: Mark all notifications as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: All unread notifications flipped to read
 */
router.patch('/read-all', notificationsController.markAllAsRead);

/**
 * @swagger
 * /api/notifications/{id}/read:
 *   patch:
 *     summary: Mark a single notification as read
 *     tags: [Notifications]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Notification marked as read
 */
router.patch('/:id/read', notificationsController.markAsRead);

module.exports = router;
