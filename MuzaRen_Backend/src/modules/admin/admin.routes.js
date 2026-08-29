const express = require('express');
const adminController = require('./admin.controller');
const analyticsController = require('./analytics.controller');
const authMiddleware = require('../../middleware/auth');
const { requireAdmin } = require('../../middleware/role');
const { validate } = require('../auth/auth.validation'); 
const { actionReportSchema, replyTicketSchema, createCategorySchema, updateCategorySchema } = require('./admin.validation');

const router = express.Router();

// ALL ROUTES ARE STRICTLY PROTECTED BY BOTH JWT AND ADMIN MIDDLEWARES SEQUENTIALLY
router.use(authMiddleware);
router.use(requireAdmin);

/**
 * @swagger
 * /api/admin/dashboard:
 *   get:
 *     summary: Retrieve globally analyzed metrics natively
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Analytical arrays extracted effectively
 */
router.get('/dashboard', adminController.getDashboardStats);

// Users

/**
 * @swagger
 * /api/admin/users/{id}/verify:
 *   patch:
 *     summary: Hard approve User Verification triggers $1000 threshold mapping
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *           format: uuid
 *         description: User ID
 *     responses:
 *       200:
 *         description: User verification approved successfully
 */

/**
 * @swagger
 * /api/admin/users/{id}/verify:
 *   patch:
 *     summary: Hard approve User Verification triggers $1000 threshold mapping
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.patch('/users/:id/verify', adminController.approveVerification);

// Listings
/**
 * @swagger
 * /api/admin/listings:
 *   get:
 *     summary: Exposes all listings regardless of unapproved status mapping
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.get('/listings', adminController.listAllListings);

/**
 * @swagger
 * /api/admin/listings/{id}/approve:
 *   patch:
 *     summary: Shifts internal mapping logic exposing listing publicly
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.patch('/listings/:id/approve', adminController.approveListing);

/**
 * @swagger
 * /api/admin/listings/{id}:
 *   delete:
 *     summary: Executes cascaded wipe breaking entire Listing relationship physically
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.delete('/listings/:id', adminController.deleteListing);

// Bookings
/**
 * @swagger
 * /api/admin/bookings:
 *   get:
 *     summary: Raw Bookings Array bypass natively
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.get('/bookings', adminController.listAllBookings);

// Reports
/**
 * @swagger
 * /api/admin/reports:
 *   get:
 *     summary: View global arrays spanning all active reports logically
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.get('/reports', adminController.listReports);

/**
 * @swagger
 * /api/admin/reports/{id}/action:
 *   patch:
 *     summary: Complete Report handling executing internal states dynamically
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.patch('/reports/:id/action', validate(actionReportSchema), adminController.actionReport);

// Reviews
/**
 * @swagger
 * /api/admin/reviews:
 *   get:
 *     summary: Bypass fetching mapping universal review contexts
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.get('/reviews', adminController.listAllReviews);

/**
 * @swagger
 * /api/admin/reviews/{id}:
 *   delete:
 *     summary: Nukes targeted review automatically triggering re-aggregation formulas upon Owner organically
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.delete('/reviews/:id', adminController.deleteReview);

// Support
/**
 * @swagger
 * /api/admin/support/tickets:
 *   get:
 *     summary: Globally retrieve targeted arrays 
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.get('/support/tickets', adminController.listAllTickets);

/**
 * @swagger
 * /api/admin/support/tickets/{id}/reply:
 *   patch:
 *     summary: Resolves logically and triggers physical user payload structurally
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.patch('/support/tickets/:id/reply', validate(replyTicketSchema), adminController.replyToTicket);

// Categories
/**
 * @swagger
 * /api/admin/categories:
 *   get:
 *     summary: View active root mappings universally 
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.get('/categories', adminController.listCategories);

/**
 * @swagger
 * /api/admin/categories:
 *   post:
 *     summary: Natively formulate root configurations
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.post('/categories', validate(createCategorySchema), adminController.createCategory);

/**
 * @swagger
 * /api/admin/categories/{id}:
 *   put:
 *     summary: Re-route mappings logic
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.put('/categories/:id', validate(updateCategorySchema), adminController.updateCategory);

/**
 * @swagger
 * /api/admin/categories/{id}:
 *   delete:
 *     summary: Break logical structures completely
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 */
router.delete('/categories/:id', adminController.deleteCategory);

// Messaging Moderation
router.get('/messages/flagged', adminController.listFlaggedMessages);
router.delete('/messages/:id', adminController.deleteMessage);

// Broadcasts
router.get('/broadcasts', adminController.listBroadcasts);
router.post('/broadcasts', adminController.sendBroadcast);

// Serviceable Cities
router.get('/cities', adminController.listCities);
router.post('/cities', adminController.createCity);
router.put('/cities/:id', adminController.updateCity);
router.delete('/cities/:id', adminController.deleteCity);


// Analytics
router.get('/analytics/overview',    analyticsController.getOverview);
router.get('/analytics/users',       analyticsController.getUsers);
router.get('/analytics/listings',    analyticsController.getListings);
router.get('/analytics/bookings',    analyticsController.getBookings);
router.get('/analytics/revenue',     analyticsController.getRevenue);
router.get('/analytics/engagement',  analyticsController.getEngagement);
router.get('/analytics/geography',   analyticsController.getGeography);
router.get('/analytics/categories',  analyticsController.getCategories);

module.exports = router;
