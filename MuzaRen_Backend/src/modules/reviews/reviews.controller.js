const reviewsService = require('./reviews.service');
const { paginationSchema } = require('./reviews.validation');

const submitReview = async (req, res, next) => {
  try {
    const review = await reviewsService.submitReview(req.user.id, req.body);
    res.status(201).json({ success: true, data: review });
  } catch (error) {
    if (error.message.includes('not authorized') || error.message.includes('completed') || error.message.includes('already')) {
      return res.status(400).json({ success: false, message: error.message });
    }
    next(error);
  }
};

const { getPaginationParams } = require('../../utils/paginate');

const getListingReviews = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await reviewsService.getListingReviews(req.params.id, { page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

const getUserReviews = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await reviewsService.getUserReviews(req.params.id, { page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  submitReview,
  getListingReviews,
  getUserReviews
};
