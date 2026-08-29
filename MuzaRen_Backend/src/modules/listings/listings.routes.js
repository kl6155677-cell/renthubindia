const express = require('express');
const listingsController = require('./listings.controller');
const authMiddleware = require('../../middleware/auth');
const { requireListingOwner } = require('../../middleware/ownership');
const { listingRateLimiter, uploadLimiter } = require('../../middleware/rateLimit');
const { validate } = require('../auth/auth.validation'); 
const { createListingSchema, updateListingSchema, updateStatusSchema } = require('./listings.validation');
const { listingImagesUpload } = require('../../config/cloudinary');

const router = express.Router();

// Publicly accessible browse endpoints
/**
 * @swagger
 * /api/listings:
 *   get:
 *     summary: Retrieve verified active listings globally
 *     tags: [Listings]
 */
router.get('/', listingsController.browseListings);

/**
 * @swagger
 * /api/listings/{id}:
 *   get:
 *     summary: Fetch single listing ID logically
 *     tags: [Listings]
 */
router.get('/:id', listingsController.getListingById);

// All mutations locked securely under authentication rules
router.use(authMiddleware);

// Retrieve isolated context maps
/**
 * @swagger
 * /api/listings/my/listings:
 *   get:
 *     summary: Retrieve all listings owned by current user
 *     tags: [Listings]
 *     security:
 *       - bearerAuth: []
 */
router.get('/my/listings', listingsController.getMyListings);

// Core CRUD utilizing RateLimiter constraints and strict body schemas
/**
 * @swagger
 * /api/listings:
 *   post:
 *     summary: Create a new marketplace listing
 *     tags: [Listings]
 *     security:
 *       - bearerAuth: []
 */
router.post('/', listingRateLimiter, validate(createListingSchema), listingsController.createListing);

/**
 * @swagger
 * /api/listings/{id}:
 *   put:
 *     summary: Update an existing listing
 *     tags: [Listings]
 *     security:
 *       - bearerAuth: []
 *   delete:
 *     summary: Permanently delete a listing
 *     tags: [Listings]
 *     security:
 *       - bearerAuth: []
 */
router.put('/:id', requireListingOwner, validate(updateListingSchema), listingsController.updateListing);
router.delete('/:id', requireListingOwner, listingsController.deleteListing);

/**
 * @swagger
 * /api/listings/{id}/status:
 *   patch:
 *     summary: Toggle listing status (ACTIVE / PAUSED)
 *     tags: [Listings]
 *     security:
 *       - bearerAuth: []
 */
router.patch('/:id/status', requireListingOwner, validate(updateStatusSchema), listingsController.updateListingStatus);

// High-capacity image endpoints natively wrapped with Cloudinary Multer pipelines
/**
 * @swagger
 * /api/listings/{id}/images:
 *   post:
 *     summary: Upload up to 5 images for a listing
 *     tags: [Listings]
 *     security:
 *       - bearerAuth: []
 */
router.post('/:id/images', requireListingOwner, uploadLimiter, listingImagesUpload, listingsController.uploadListingImages);

module.exports = router;
