const express = require('express');
const supportController = require('./support.controller');
const authMiddleware = require('../../middleware/auth');
const { validate } = require('../auth/auth.validation'); 
const { createTicketSchema } = require('./support.validation');

const router = express.Router();

router.use(authMiddleware);

// Exclusively mounted at /api/support/tickets internally
/**
 * @swagger
 * /api/support/tickets:
 *   post:
 *     summary: Open a new support ticket
 *     tags: [Support]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [subject, message]
 *             properties:
 *               subject:
 *                 type: string
 *               message:
 *                 type: string
 *     responses:
 *       201:
 *         description: Ticket opened under OPEN status
 */
router.post('/tickets', validate(createTicketSchema), supportController.createTicket);
/**
 * @swagger
 * /api/support/tickets:
 *   get:
 *     summary: Collect your historical support tickets globally
 *     tags: [Support]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Target arrays effectively extracted
 */
router.get('/tickets', supportController.getMyTickets);

/**
 * @swagger
 * /api/support/tickets/{id}:
 *   get:
 *     summary: View a single ticket (ownership enforced)
 *     tags: [Support]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Ticket details
 */
router.get('/tickets/:id', supportController.getTicketById);

module.exports = router;
