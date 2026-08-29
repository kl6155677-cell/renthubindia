const express = require('express');
const categoriesController = require('./categories.controller');

const router = express.Router();

/**
 * @swagger
 * /api/categories:
 *   get:
 *     summary: Retrieve all platform categories
 *     tags: [Categories]
 *     responses:
 *       200:
 *         description: Array of categories
 */
router.get('/', categoriesController.getAllCategories);

module.exports = router;
