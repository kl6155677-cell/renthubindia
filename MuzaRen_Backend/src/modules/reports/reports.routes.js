const express = require('express');
const reportsController = require('./reports.controller');
const authMiddleware = require('../../middleware/auth');
const { validate } = require('../auth/auth.validation'); 
const { submitReportSchema } = require('./reports.validation');

const router = express.Router();

router.use(authMiddleware);
/**
 * @swagger
 * /api/reports:
 *   post:
 *     summary: Submit a report against a listing, user, or message
 *     tags: [Reports]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [targetType, targetId, category]
 *             properties:
 *               targetType:
 *                 type: string
 *                 enum: [LISTING, USER, MESSAGE]
 *               targetId:
 *                 type: string
 *               category:
 *                 type: string
 *                 enum: [FRAUD, SPAM, ABUSE, FAKE_LISTING]
 *               description:
 *                 type: string
 *     responses:
 *       201:
 *         description: Report submitted and pending admin review
 */
router.post('/', validate(submitReportSchema), reportsController.submitReport);

module.exports = router;
