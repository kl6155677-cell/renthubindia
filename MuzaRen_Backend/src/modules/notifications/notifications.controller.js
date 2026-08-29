const notificationsService = require('./notifications.service');

const { getPaginationParams } = require('../../utils/paginate');

const getUserNotifications = async (req, res, next) => {
  try {
    const { page, limit } = getPaginationParams(req.query);
    const result = await notificationsService.getUserNotifications(req.user.id, { page, limit });
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

const markAsRead = async (req, res, next) => {
  try {
    const notification = await notificationsService.markAsRead(req.user.id, req.params.id);
    res.status(200).json({ success: true, data: notification });
  } catch (error) {
    if (error.message.includes('Unauthorized') || error.message.includes('not found')) {
      return res.status(403).json({ success: false, message: error.message });
    }
    next(error);
  }
};

const markAllAsRead = async (req, res, next) => {
  try {
    const result = await notificationsService.markAllAsRead(req.user.id);
    res.status(200).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getUserNotifications,
  markAsRead,
  markAllAsRead
};
