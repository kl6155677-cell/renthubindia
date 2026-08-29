const bookingsService = require('./bookings.service');

const createBooking = async (req, res, next) => {
  try {
    const booking = await bookingsService.createBooking(req.user.id, req.body);
    res.status(201).json({ success: true, data: booking });
  } catch (error) {
    if (error.message.includes('unavailable') || 
        error.message.includes('overlapping') ||
        error.message.includes('your own')) {
          return res.status(400).json({ success: false, message: error.message });
    }
    next(error);
  }
};

const { getPaginationParams } = require('../../utils/paginate');

const getMyBookings = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await bookingsService.getMyBookings(req.user.id, { ...req.query, page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

const getIncomingBookings = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await bookingsService.getIncomingBookings(req.user.id, { ...req.query, page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

const acceptBooking = async (req, res, next) => {
  try {
    const booking = await bookingsService.acceptBooking(req.user.id, req.params.id);
    res.status(200).json({ success: true, data: booking });
  } catch (error) {
    console.log('❌ Accept Booking Error:', error);
    if (error.message === 'Unauthorized') return res.status(403).json({ success: false, message: error.message });
    return res.status(400).json({ success: false, message: error.message });
  }
};

const cancelBooking = async (req, res, next) => {
  try {
    const booking = await bookingsService.cancelBooking(req.user.id, req.params.id);
    res.status(200).json({ success: true, data: booking });
  } catch (error) {
    if (error.message === 'Unauthorized') return res.status(403).json({ success: false, message: error.message });
    return res.status(400).json({ success: false, message: error.message });
  }
};

const completeBooking = async (req, res, next) => {
  try {
    const booking = await bookingsService.completeBooking(req.user.id, req.params.id);
    res.status(200).json({ success: true, data: booking });
  } catch (error) {
    if (error.message === 'Unauthorized') return res.status(403).json({ success: false, message: error.message });
    return res.status(400).json({ success: false, message: error.message });
  }
};

module.exports = {
  createBooking,
  getMyBookings,
  getIncomingBookings,
  acceptBooking,
  cancelBooking,
  completeBooking
};
