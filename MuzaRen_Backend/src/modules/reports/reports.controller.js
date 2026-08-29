const reportsService = require('./reports.service');

const submitReport = async (req, res, next) => {
  try {
    const report = await reportsService.submitReport(req.user.id, req.body);
    res.status(201).json({ success: true, data: report });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  submitReport
};
