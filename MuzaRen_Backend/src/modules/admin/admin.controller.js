const adminService = require('./admin.service');
const { getPaginationParams } = require('../../utils/paginate');
const { paginationSchema, actionReportSchema, replyTicketSchema, createCategorySchema, updateCategorySchema } = require('./admin.validation');

// DASHBOARD
exports.getDashboardStats = async (req, res, next) => {
  try { res.status(200).json({ success: true, data: await adminService.getDashboardStats() }); } catch (error) { next(error); }
};

// USERS
exports.approveVerification = async (req, res, next) => {
  try { res.status(200).json({ success: true, data: await adminService.approveVerification(req.params.id) }); } catch (error) { next(error); }
};

// LISTINGS
exports.listAllListings = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await adminService.listAllListings({ ...req.query, page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};
exports.approveListing = async (req, res, next) => {
  try { res.status(200).json({ success: true, data: await adminService.approveListing(req.params.id, req.body.isApproved) }); } catch (error) { next(error); }
};
exports.deleteListing = async (req, res, next) => {
  try { res.status(200).json({ success: true, data: await adminService.deleteListing(req.params.id) }); } catch (error) { next(error); }
};

// BOOKINGS
exports.listAllBookings = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await adminService.listAllBookings({ ...req.query, page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

// REPORTS

exports.listReports = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await adminService.listReports({ ...req.query, page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};
exports.actionReport = async (req, res, next) => {
  try { res.status(200).json({ success: true, data: await adminService.actionReport(req.params.id, req.body.status, req.body.adminNote) }); } catch (error) { next(error); }
};

// CITIES
exports.listCities = async (req, res, next) => {
  try {
    const result = await adminService.listCities();
    res.status(200).json({ success: true, data: result });
  } catch (error) { next(error); }
};

exports.createCity = async (req, res, next) => {
  try {
    const result = await adminService.createCity(req.body);
    res.status(201).json({ success: true, data: result });
  } catch (error) { next(error); }
};

exports.updateCity = async (req, res, next) => {
  try {
    const result = await adminService.updateCity(req.params.id, req.body);
    res.status(200).json({ success: true, data: result });
  } catch (error) { next(error); }
};

exports.deleteCity = async (req, res, next) => {
  try {
    const result = await adminService.deleteCity(req.params.id);
    res.status(200).json({ success: true, data: result });
  } catch (error) { next(error); }
};

// REVIEWS
exports.listAllReviews = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await adminService.listAllReviews({ page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};
exports.deleteReview = async (req, res, next) => {
  try { res.status(200).json({ success: true, data: await adminService.deleteReview(req.params.id) }); } catch (error) { next(error); }
};

// TICKETS
exports.listAllTickets = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await adminService.listAllTickets({ ...req.query, page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};
exports.replyToTicket = async (req, res, next) => {
  try { res.status(200).json({ success: true, data: await adminService.replyToTicket(req.params.id, req.body.adminReply) }); } catch (error) { next(error); }
};

// CATEGORIES
exports.listCategories = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await adminService.listCategories({ ...req.query, page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};
exports.createCategory = async (req, res, next) => {
  try { res.status(201).json({ success: true, data: await adminService.createCategory(req.body) }); } catch (error) { next(error); }
};
exports.updateCategory = async (req, res, next) => {
  try { res.status(200).json({ success: true, data: await adminService.updateCategory(req.params.id, req.body) }); } catch (error) { next(error); }
};
exports.deleteCategory = async (req, res, next) => {
  try { res.status(200).json({ success: true, data: await adminService.deleteCategory(req.params.id) }); } catch (error) { next(error); }
};

// MESSAGING MODERATION
exports.listFlaggedMessages = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await adminService.listFlaggedMessages({ page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

exports.deleteMessage = async (req, res, next) => {
  try {
    res.status(200).json({ success: true, message: await adminService.deleteMessage(req.params.id, req.body.reason) });
  } catch (error) {
    next(error);
  }
};

// BROADCASTS
exports.listBroadcasts = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await adminService.listBroadcasts({ page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

exports.sendBroadcast = async (req, res, next) => {
  try {
    res.status(201).json({ success: true, data: await adminService.sendBroadcast(req.body) });
  } catch (error) {
    next(error);
  }
};

// ANALYTICS
exports.getAnalytics = async (req, res, next) => {
  try {
    const { range } = req.query;
    const data = await adminService.getAnalytics(range);
    res.status(200).json({ success: true, data });
  } catch (error) {
    next(error);
  }
};
