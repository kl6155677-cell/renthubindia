const express = require('express');
const reviewsController = require('./reviews.controller');
const authMiddleware = require('../../middleware/auth');
const { validate } = require('../auth/auth.validation'); 
const { submitReviewSchema } = require('./reviews.validation');

const router = express.Router();

// Publicly observable historical reviews for prospective users
/**
 * @swagger
 * /api/reviews/listing/{id}:
 *   get:
 *     summary: Retrieve reviews for a specific listing
 *     tags: [Reviews]
 */
router.get('/listing/:id', reviewsController.getListingReviews);
/**
 * @swagger
 * /api/reviews/user/{id}:
 *   get:
 *     summary: Retrieve reviews for a specific user
 *     tags: [Reviews]
 */
router.get('/user/:id', reviewsController.getUserReviews);

// Secure mapping 
router.use(authMiddleware);
/**
 * @swagger
 * /api/reviews:
 *   post:
 *     summary: Log a review structure dynamically
 *     tags: [Reviews]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       201:
 *         description: Review natively pushed and User recalibrated
 */
router.post('/', validate(submitReviewSchema), reviewsController.submitReview);

module.exports = router;
