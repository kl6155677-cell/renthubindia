const express = require('express');
const citiesController = require('./cities.controller');

const router = express.Router();

/**
 * @swagger
 * /api/cities/active:
 *   get:
 *     summary: Get a list of all active serviceable cities
 *     tags: [Cities]
 *     responses:
 *       200:
 *         description: List of active cities
 */
router.get('/active', citiesController.getActiveCities);

module.exports = router;
