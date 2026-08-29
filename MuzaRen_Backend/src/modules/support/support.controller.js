const supportService = require('./support.service');

const createTicket = async (req, res, next) => {
  try {
    const ticket = await supportService.createTicket(req.user.id, req.body);
    res.status(201).json({ success: true, data: ticket });
  } catch (error) {
    next(error);
  }
};

const { getPaginationParams } = require('../../utils/paginate');

const getMyTickets = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await supportService.getMyTickets(req.user.id, { ...req.query, page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

const getTicketById = async (req, res, next) => {
  try {
    const ticket = await supportService.getTicketById(req.user.id, req.params.id);
    res.status(200).json({ success: true, data: ticket });
  } catch (error) {
    if (error.message.includes('Unauthorized') || error.message.includes('not found')) {
      return res.status(403).json({ success: false, message: error.message });
    }
    next(error);
  }
};

module.exports = {
  createTicket,
  getMyTickets,
  getTicketById
};
