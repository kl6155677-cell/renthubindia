const express = require('express');
const bookingsController = require('./bookings.controller');
const authMiddleware = require('../../middleware/auth');
const { validate } = require('../auth/auth.validation'); 
const { createBookingSchema } = require('./bookings.validation');

const router = express.Router();

// The entire Bookings network is strictly authenticated
router.use(authMiddleware);

// Core Booking Logic
/**
 * @swagger
 * /api/bookings:
 *   post:
 *     summary: Initiate a new Booking block
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       201:
 *         description: Booking logic initialized safely
 */
router.post('/', validate(createBookingSchema), bookingsController.createBooking);

// Profile Isolation Lists
/**
 * @swagger
 * /api/bookings/my:
 *   get:
 *     summary: Retrieve user's outgoing bookings
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Array of your rented bookings
 */
router.get('/my', bookingsController.getMyBookings);

/**
 * @swagger
 * /api/bookings/incoming:
 *   get:
 *     summary: Retrieve user's incoming booking requests
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Array of requests on your listings
 */
router.get('/incoming', bookingsController.getIncomingBookings);

// State Flow Manipulations
/**
 * @swagger
 * /api/bookings/{id}/accept:
 *   patch:
 *     summary: Owner explicitly accepts booking requests
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Booking logically moves to ACCEPTED
 */
router.patch('/:id/accept', bookingsController.acceptBooking);

/**
 * @swagger
 * /api/bookings/{id}/cancel:
 *   patch:
 *     summary: Cancels an active or pending booking network request
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Triggers a state break directly to CANCELLED
 */
router.patch('/:id/cancel', bookingsController.cancelBooking);

/**
 * @swagger
 * /api/bookings/{id}/complete:
 *   patch:
 *     summary: Finalize an accepted booking safely into completeness
 *     tags: [Bookings]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Fully concludes the rental bounds locking status identically
 */
router.patch('/:id/complete', bookingsController.completeBooking);

module.exports = router;
