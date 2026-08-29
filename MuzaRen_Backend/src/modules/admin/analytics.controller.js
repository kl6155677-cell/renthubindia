const analyticsService = require('./analytics.service');

const wrap = fn => async (req, res) => {
  try {
    const { period, country, startDate, endDate } = req.query;
    const data = await fn(period, country, startDate, endDate);
    res.json({ success: true, data });
  } catch (err) {
    console.error('Analytics error:', err);
    res.status(500).json({ error: 'Failed to fetch analytics data' });
  }
};

module.exports = {
  getOverview:    wrap((p, c) => analyticsService.getOverview(p, c)),
  getUsers:       wrap((p, c) => analyticsService.getUserAnalytics(p, c)),
  getListings:    wrap((p, c) => analyticsService.getListingAnalytics(p, c)),
  getBookings:    wrap((p, c) => analyticsService.getBookingAnalytics(p, c)),
  getRevenue:     wrap((p, c) => analyticsService.getRevenueAnalytics(p, c)),
  getEngagement:  wrap((p)    => analyticsService.getEngagementAnalytics(p)),
  getGeography:   wrap(()     => analyticsService.getGeographyAnalytics()),
  getCategories:  wrap(()     => analyticsService.getCategoryAnalytics()),
};
