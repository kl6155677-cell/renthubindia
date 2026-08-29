const listingsService = require('./listings.service');
const { browseSchema } = require('./listings.validation');

const { getPaginationParams } = require('../../utils/paginate');

const browseListings = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const filters = browseSchema.parse({ ...req.query, page, limit });
    const result = await listingsService.browseListings(filters);
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

const getListingById = async (req, res, next) => {
  try {
    const listing = await listingsService.getListingById(req.params.id);
    res.status(200).json({ success: true, data: listing });
  } catch (error) {
    if (error.message === 'Listing not found' || error.message.includes('unavailable')) {
      return res.status(404).json({ success: false, message: error.message });
    }
    next(error);
  }
};

const createListing = async (req, res, next) => {
  try {
    const listing = await listingsService.createListing(req.user.id, req.body, req.user);
    res.status(201).json({ success: true, data: listing });
  } catch (error) {
    if (error.message.includes('VERIFIED')) {
      return res.status(403).json({ success: false, message: error.message });
    }
    next(error);
  }
};

const updateListing = async (req, res, next) => {
  try {
    const listing = await listingsService.updateListing(req.user.id, req.params.id, req.body);
    res.status(200).json({ success: true, data: listing });
  } catch (error) {
    if (error.message.includes('Unauthorized')) {
      return res.status(403).json({ success: false, message: error.message });
    }
    next(error);
  }
};

const deleteListing = async (req, res, next) => {
  try {
    const result = await listingsService.deleteListing(req.user.id, req.params.id);
    res.status(200).json({ success: true, message: result.message });
  } catch (error) {
    if (error.message.includes('Unauthorized')) {
      return res.status(403).json({ success: false, message: error.message });
    }
    next(error);
  }
};

const updateListingStatus = async (req, res, next) => {
  try {
    const listing = await listingsService.updateListingStatus(req.user.id, req.params.id, req.body.status);
    res.status(200).json({ success: true, data: listing });
  } catch (error) {
    if (error.message.includes('Unauthorized')) {
      return res.status(403).json({ success: false, message: error.message });
    }
    next(error);
  }
};

const getMyListings = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await listingsService.getMyListings(req.user.id, { page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

const uploadListingImages = async (req, res, next) => {
  try {
    const result = await listingsService.uploadListingImages(req.user.id, req.params.id, req.files);
    res.status(200).json({ success: true, message: result.message });
  } catch (error) {
    if (error.message.includes('Unauthorized')) {
      return res.status(403).json({ success: false, message: error.message });
    }
    next(error);
  }
};

module.exports = {
  browseListings,
  getListingById,
  createListing,
  updateListing,
  deleteListing,
  updateListingStatus,
  getMyListings,
  uploadListingImages
};
