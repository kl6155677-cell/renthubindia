const prisma = require('../../config/db');

/**
 * Function 1: getOverview(period, country)
 * Returns the top-level KPI cards for the dashboard.
 */
async function getOverview(period = '30d', country = null) {
  const { getStartDate, getPreviousPeriodStart, calculateGrowth } =
    require('../../utils/analyticsHelpers');

  const startDate    = getStartDate(period);
  const prevStart    = getPreviousPeriodStart(period);
  const prevEnd      = startDate;
  const countryWhere = country ? { country } : {};

  // Run all queries in parallel for performance
  const [
    totalUsers,
    newUsers,
    prevNewUsers,
    totalListings,
    newListings,
    prevNewListings,
    totalBookings,
    newBookings,
    prevNewBookings,
    activeListings,
    pendingVerifications,
    openReports,
    openTickets,
    completedBookings,
    cancelledBookings,
  ] = await Promise.all([
    // Total users ever
    prisma.user.count({ where: { role: 'USER', ...countryWhere } }),
    // New users in current period
    prisma.user.count({
      where: { role: 'USER', createdAt: { gte: startDate }, ...countryWhere }
    }),
    // New users in previous period (for growth %)
    prisma.user.count({
      where: { role: 'USER',
        createdAt: { gte: prevStart, lt: prevEnd }, ...countryWhere }
    }),
    // Total listings ever
    prisma.listing.count({ where: { ...countryWhere } }),
    // New listings in current period
    prisma.listing.count({
      where: { createdAt: { gte: startDate }, ...countryWhere }
    }),
    // New listings in previous period
    prisma.listing.count({
      where: { createdAt: { gte: prevStart, lt: prevEnd }, ...countryWhere }
    }),
    // Total bookings ever
    prisma.booking.count(),
    // New bookings in current period
    prisma.booking.count({ where: { createdAt: { gte: startDate } } }),
    // New bookings in previous period
    prisma.booking.count({
      where: { createdAt: { gte: prevStart, lt: prevEnd } }
    }),
    // Currently active listings
    prisma.listing.count({
      where: { status: 'ACTIVE', isApproved: true, ...countryWhere }
    }),
    // Pending identity verifications
    prisma.user.count({ where: { verificationStatus: 'PENDING' } }),
    // Open reports needing action
    prisma.report.count({ where: { status: 'OPEN' } }),
    // Open support tickets
    prisma.supportTicket.count({ where: { status: 'OPEN' } }),
    // Completed bookings in period
    prisma.booking.count({
      where: { status: 'COMPLETED', createdAt: { gte: startDate } }
    }),
    // Cancelled bookings in period
    prisma.booking.count({
      where: { status: 'CANCELLED', createdAt: { gte: startDate } }
    }),
  ]);

  // Calculate booking completion rate
  const completionRate = newBookings > 0
    ? Math.round((completedBookings / newBookings) * 100)
    : 0;

  return {
    period,
    kpis: {
      totalUsers: {
        value:  totalUsers,
        new:    newUsers,
        growth: calculateGrowth(newUsers, prevNewUsers),
        label:  'Total Users',
      },
      totalListings: {
        value:  totalListings,
        new:    newListings,
        growth: calculateGrowth(newListings, prevNewListings),
        label:  'Total Listings',
      },
      totalBookings: {
        value:  totalBookings,
        new:    newBookings,
        growth: calculateGrowth(newBookings, prevNewBookings),
        label:  'Total Bookings',
      },
      activeListings: {
        value: activeListings,
        label: 'Active Listings',
      },
    },
    alerts: {
      pendingVerifications,
      openReports,
      openTickets,
    },
    bookingHealth: {
      completed:      completedBookings,
      cancelled:      cancelledBookings,
      completionRate, // percentage of bookings that completed
    },
  };
}

/**
 * Function 2: getUserAnalytics(period, country)
 * Returns user growth, verification funnel, retention data.
 */
async function getUserAnalytics(period = '30d', country = null) {
  const { getStartDate, groupByPeriod } = require('../../utils/analyticsHelpers');
  const startDate    = getStartDate(period);
  const countryWhere = country ? { country } : {};

  const [
    allNewUsers,
    verificationCounts,
    blockedUsers,
    usersByCountry,
    activeUsers,
  ] = await Promise.all([
    // All new users in period (for time-series chart)
    prisma.user.findMany({
      where: { role: 'USER', createdAt: { gte: startDate }, ...countryWhere },
      select: { createdAt: true },
      orderBy: { createdAt: 'asc' },
    }),
    // Verification status breakdown
    prisma.user.groupBy({
      by: ['verificationStatus'],
      where: { role: 'USER', ...countryWhere },
      _count: { id: true },
    }),
    // Blocked users count
    prisma.user.count({ where: { isBlocked: true, ...countryWhere } }),
    // Users by country (top 10)
    prisma.user.groupBy({
      by: ['country'],
      where: { role: 'USER' },
      _count: { id: true },
      orderBy: { _count: { id: 'desc' } },
      take: 10,
    }),
    // Users who made at least one booking (active users)
    prisma.booking.findMany({
      where: { createdAt: { gte: startDate } },
      select: { renterId: true },
      distinct: ['renterId'],
    }),
  ]);

  // Group new users by time period
  const userGrowthChart = groupByPeriod(allNewUsers, 'createdAt', period);

  // Format verification funnel
  const verificationFunnel = {
    UNVERIFIED: 0,
    PENDING:    0,
    VERIFIED:   0,
  };
  verificationCounts.forEach(v => {
    verificationFunnel[v.verificationStatus] = v._count.id;
  });

  // Format countries
  const topCountries = usersByCountry
    .filter(c => c.country)
    .map(c => ({ country: c.country, count: c._count.id }));

  return {
    userGrowthChart,    // time-series: [{ date, count }]
    verificationFunnel, // { UNVERIFIED: n, PENDING: n, VERIFIED: n }
    blockedUsers,
    topCountries,       // [{ country, count }]
    activeUsersCount: activeUsers.length,
  };
}

/**
 * Function 3: getListingAnalytics(period, country)
 * Returns listing growth, category breakdown, approval rates.
 */
async function getListingAnalytics(period = '30d', country = null) {
  const { getStartDate, groupByPeriod } = require('../../utils/analyticsHelpers');
  const startDate    = getStartDate(period);
  const countryWhere = country ? { country } : {};

  const [
    allNewListings,
    listingsByStatus,
    listingsByCategory,
    approvalStats,
    topListedCountries,
    avgPriceByCategory,
  ] = await Promise.all([
    // Time-series data
    prisma.listing.findMany({
      where: { createdAt: { gte: startDate }, ...countryWhere },
      select: { createdAt: true },
      orderBy: { createdAt: 'asc' },
    }),
    // Listings by status
    prisma.listing.groupBy({
      by: ['status'],
      where: { ...countryWhere },
      _count: { id: true },
    }),
    // Listings by category (top 10)
    prisma.listing.groupBy({
      by: ['categoryId'],
      where: { ...countryWhere },
      _count: { id: true },
      orderBy: { _count: { id: 'desc' } },
      take: 10,
    }),
    // Approval rate
    Promise.all([
      prisma.listing.count({ where: { isApproved: true, ...countryWhere } }),
      prisma.listing.count({ where: { isApproved: false, ...countryWhere } }),
    ]),
    // Top countries for listings
    prisma.listing.groupBy({
      by: ['country'],
      where: { status: 'ACTIVE' },
      _count: { id: true },
      orderBy: { _count: { id: 'desc' } },
      take: 10,
    }),
    // Average price per category
    prisma.listing.groupBy({
      by: ['categoryId'],
      where: { status: 'ACTIVE', ...countryWhere },
      _avg: { pricePerDay: true },
      orderBy: { _avg: { pricePerDay: 'desc' } },
      take: 10,
    }),
  ]);

  // Enrich category data with names
  const categoryIds = [
    ...new Set([
      ...listingsByCategory.map(l => l.categoryId),
      ...avgPriceByCategory.map(l => l.categoryId),
    ])
  ];
  const categories = await prisma.category.findMany({
    where: { id: { in: categoryIds } },
    select: { id: true, name: true },
  });
  const categoryMap = Object.fromEntries(categories.map(c => [c.id, c.name]));

  const listingGrowthChart = groupByPeriod(allNewListings, 'createdAt', period);

  const statusBreakdown = {};
  listingsByStatus.forEach(s => { statusBreakdown[s.status] = s._count.id; });

  const categoryBreakdown = listingsByCategory.map(l => ({
    category: categoryMap[l.categoryId] || 'Unknown',
    count:    l._count.id,
  }));

  const avgPriceChart = avgPriceByCategory.map(l => ({
    category: categoryMap[l.categoryId] || 'Unknown',
    avgPrice: Math.round(l._avg.pricePerDay || 0),
  }));

  const [approved, pending] = approvalStats;
  const approvalRate = (approved + pending) > 0
    ? Math.round((approved / (approved + pending)) * 100)
    : 0;

  return {
    listingGrowthChart,  // [{ date, count }]
    statusBreakdown,     // { ACTIVE: n, PAUSED: n, EXPIRED: n }
    categoryBreakdown,   // [{ category, count }]
    avgPriceChart,       // [{ category, avgPrice }]
    approvalRate,        // percentage
    approved,
    pendingApproval: pending,
    topListedCountries: topListedCountries
      .filter(c => c.country)
      .map(c => ({ country: c.country, count: c._count.id })),
  };
}

/**
 * Function 4: getBookingAnalytics(period, country)
 * Returns booking trends, status funnel, completion rates.
 */
async function getBookingAnalytics(period = '30d', country = null) {
  const { getStartDate, groupByPeriod } = require('../../utils/analyticsHelpers');
  const startDate = getStartDate(period);

  const [
    allNewBookings,
    bookingsByStatus,
    avgBookingDuration,
    bookingsByDayOfWeek,
    topBookedCategories,
  ] = await Promise.all([
    // Time-series
    prisma.booking.findMany({
      where: { createdAt: { gte: startDate } },
      select: { createdAt: true, startDate: true, endDate: true },
      orderBy: { createdAt: 'asc' },
    }),
    // Status breakdown
    prisma.booking.groupBy({
      by: ['status'],
      where: { createdAt: { gte: startDate } },
      _count: { id: true },
    }),
    // Average rental duration (endDate - startDate in days)
    prisma.booking.aggregate({
      where: {
        createdAt: { gte: startDate },
        status: { in: ['COMPLETED', 'ACCEPTED'] },
      },
      _avg: { totalPrice: true },
    }),
    // Bookings by day of week (0=Sunday ... 6=Saturday)
    prisma.booking.findMany({
      where: { createdAt: { gte: startDate } },
      select: { createdAt: true },
    }),
    // Top booked categories
    prisma.booking.findMany({
      where: { createdAt: { gte: startDate } },
      select: {
        listing: {
          select: {
            categoryId: true,
            category:   { select: { name: true } },
          },
        },
      },
    }),
  ]);

  const bookingGrowthChart = groupByPeriod(allNewBookings, 'createdAt', period);

  // Status funnel
  const statusFunnel = { PENDING: 0, ACCEPTED: 0, COMPLETED: 0, CANCELLED: 0 };
  bookingsByStatus.forEach(s => { statusFunnel[s.status] = s._count.id; });

  // Completion rate
  const total     = Object.values(statusFunnel).reduce((a, b) => a + b, 0);
  const completionRate = total > 0
    ? Math.round((statusFunnel.COMPLETED / total) * 100) : 0;
  const cancellationRate = total > 0
    ? Math.round((statusFunnel.CANCELLED / total) * 100) : 0;

  // Bookings by day of week
  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const dayCount = { 0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0 };
  allNewBookings.forEach(b => {
    const day = new Date(b.createdAt).getDay();
    dayCount[day]++;
  });
  const bookingsByDay = dayNames.map((name, i) => ({ day: name, count: dayCount[i] }));

  // Top booked categories
  const catCounts = {};
  topBookedCategories.forEach(b => {
    if (b.listing?.category?.name) {
      const name = b.listing.category.name;
      catCounts[name] = (catCounts[name] || 0) + 1;
    }
  });
  const topCategories = Object.entries(catCounts)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 8)
    .map(([category, count]) => ({ category, count }));

  // Average rental duration
  let avgDuration = 0;
  const withDates = allNewBookings.filter(b => b.startDate && b.endDate);
  if (withDates.length > 0) {
    const totalDays = withDates.reduce((sum, b) => {
      return sum + Math.ceil(
        (new Date(b.endDate) - new Date(b.startDate)) / 86400000
      );
    }, 0);
    avgDuration = Math.round(totalDays / withDates.length);
  }

  return {
    bookingGrowthChart, // [{ date, count }]
    statusFunnel,       // { PENDING, ACCEPTED, COMPLETED, CANCELLED }
    completionRate,
    cancellationRate,
    bookingsByDay,      // [{ day, count }]
    topCategories,      // [{ category, count }]
    avgDuration,        // avg days per rental
    avgBookingValue: Math.round(avgBookingDuration._avg?.totalPrice || 0),
  };
}

/**
 * Function 5: getRevenueAnalytics(period, country)
 * Returns potential revenue (total booking value — no payments yet).
 */
async function getRevenueAnalytics(period = '30d', country = null) {
  const { getStartDate, getPreviousPeriodStart, groupByPeriod, calculateGrowth } =
    require('../../utils/analyticsHelpers');
  const startDate = getStartDate(period);
  const prevStart = getPreviousPeriodStart(period);

  const [
    currentPeriodBookings,
    previousPeriodBookings,
    revenueByCategory,
    topEarningListings,
    revenueByCountry,
  ] = await Promise.all([
    // All bookings in period with total price
    prisma.booking.findMany({
      where: {
        createdAt: { gte: startDate },
        status: { in: ['ACCEPTED', 'COMPLETED'] },
      },
      select: { totalPrice: true, createdAt: true },
      orderBy: { createdAt: 'asc' },
    }),
    // Previous period for comparison
    prisma.booking.findMany({
      where: {
        createdAt: { gte: prevStart, lt: startDate },
        status: { in: ['ACCEPTED', 'COMPLETED'] },
      },
      select: { totalPrice: true },
    }),
    // Revenue by category
    prisma.booking.findMany({
      where: {
        createdAt: { gte: startDate },
        status: { in: ['ACCEPTED', 'COMPLETED'] },
      },
      select: {
        totalPrice: true,
        listing: {
          select: { category: { select: { name: true } } }
        },
      },
    }),
    // Top 10 highest-value listings
    prisma.booking.groupBy({
      by: ['listingId'],
      where: {
        createdAt: { gte: startDate },
        status: { in: ['ACCEPTED', 'COMPLETED'] },
      },
      _sum: { totalPrice: true },
      _count: { id: true },
      orderBy: { _sum: { totalPrice: 'desc' } },
      take: 10,
    }),
    // Revenue by country
    prisma.booking.findMany({
      where: {
        createdAt: { gte: startDate },
        status: { in: ['ACCEPTED', 'COMPLETED'] },
      },
      select: {
        totalPrice: true,
        listing: { select: { country: true } },
      },
    }),
  ]);

  // Total revenue
  const totalRevenue = currentPeriodBookings
    .reduce((sum, b) => sum + (b.totalPrice || 0), 0);
  const prevRevenue = previousPeriodBookings
    .reduce((sum, b) => sum + (b.totalPrice || 0), 0);
  const revenueGrowth = calculateGrowth(totalRevenue, prevRevenue);

  // Revenue time-series
  const revenueByDay = {};
  currentPeriodBookings.forEach(b => {
    const date = new Date(b.createdAt).toISOString().split('T')[0];
    revenueByDay[date] = (revenueByDay[date] || 0) + (b.totalPrice || 0);
  });
  const revenueChart = Object.entries(revenueByDay)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([date, revenue]) => ({ date, revenue: Math.round(revenue) }));

  // Revenue by category
  const catRevenue = {};
  revenueByCategory.forEach(b => {
    const name = b.listing?.category?.name || 'Unknown';
    catRevenue[name] = (catRevenue[name] || 0) + (b.totalPrice || 0);
  });
  const revenueByCategoryChart = Object.entries(catRevenue)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 8)
    .map(([category, revenue]) => ({ category, revenue: Math.round(revenue) }));

  // Revenue by country
  const countryRevenue = {};
  revenueByCountry.forEach(b => {
    const c = b.listing?.country || 'Unknown';
    countryRevenue[c] = (countryRevenue[c] || 0) + (b.totalPrice || 0);
  });
  const revenueByCountryChart = Object.entries(countryRevenue)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 10)
    .map(([country, revenue]) => ({ country, revenue: Math.round(revenue) }));

  // Enrich top listings with titles
  const listingIds = topEarningListings.map(l => l.listingId);
  const listings = await prisma.listing.findMany({
    where: { id: { in: listingIds } },
    select: { id: true, title: true, pricePerDay: true },
  });
  const listingMap = Object.fromEntries(listings.map(l => [l.id, l]));

  const topListings = topEarningListings.map(l => ({
    id:           l.listingId,
    title:        listingMap[l.listingId]?.title || 'Unknown',
    pricePerDay:  listingMap[l.listingId]?.pricePerDay || 0,
    totalRevenue: Math.round(l._sum.totalPrice || 0),
    bookings:     l._count.id,
  }));

  return {
    totalRevenue:          Math.round(totalRevenue),
    revenueGrowth,
    avgRevenuePerBooking:  currentPeriodBookings.length > 0
      ? Math.round(totalRevenue / currentPeriodBookings.length) : 0,
    revenueChart,            // [{ date, revenue }]
    revenueByCategoryChart,  // [{ category, revenue }]
    revenueByCountryChart,   // [{ country, revenue }]
    topListings,             // [{ title, totalRevenue, bookings }]
  };
}

/**
 * Function 6: getEngagementAnalytics(period)
 * Returns chat, reviews, reports, support engagement metrics.
 */
async function getEngagementAnalytics(period = '30d') {
  const { getStartDate } = require('../../utils/analyticsHelpers');
  const startDate = getStartDate(period);

  const [
    totalMessages,
    totalChats,
    totalReviews,
    avgRating,
    ratingDistribution,
    totalReports,
    reportsByCategory,
    resolvedReports,
    totalTickets,
    resolvedTickets,
    avgTicketResolutionTime,
  ] = await Promise.all([
    prisma.message.count({ where: { createdAt: { gte: startDate } } }),
    prisma.chat.count({ where: { createdAt: { gte: startDate } } }),
    prisma.review.count({ where: { createdAt: { gte: startDate } } }),
    prisma.review.aggregate({
      where: { createdAt: { gte: startDate } },
      _avg: { rating: true },
    }),
    // Rating distribution (1-5 stars)
    prisma.review.groupBy({
      by: ['rating'],
      where: { createdAt: { gte: startDate } },
      _count: { id: true },
      orderBy: { rating: 'asc' },
    }),
    prisma.report.count({ where: { createdAt: { gte: startDate } } }),
    prisma.report.groupBy({
      by: ['category'],
      where: { createdAt: { gte: startDate } },
      _count: { id: true },
    }),
    prisma.report.count({
      where: { status: 'RESOLVED', updatedAt: { gte: startDate } }
    }),
    prisma.supportTicket.count({ where: { createdAt: { gte: startDate } } }),
    prisma.supportTicket.count({
      where: {
        status: { in: ['RESOLVED', 'CLOSED'] },
        updatedAt: { gte: startDate },
      }
    }),
    // Avg ticket resolution time (updatedAt - createdAt for resolved tickets)
    prisma.supportTicket.findMany({
      where: {
        status: { in: ['RESOLVED', 'CLOSED'] },
        updatedAt: { gte: startDate },
      },
      select: { createdAt: true, updatedAt: true },
      take: 100,
    }),
  ]);

  // Calculate avg resolution time in hours
  let avgResolutionHours = 0;
  if (avgTicketResolutionTime.length > 0) {
    const totalHours = avgTicketResolutionTime.reduce((sum, t) => {
      return sum + (new Date(t.updatedAt) - new Date(t.createdAt)) / 3600000;
    }, 0);
    avgResolutionHours = Math.round(totalHours / avgTicketResolutionTime.length);
  }

  // Format rating distribution
  const ratingDist = [1, 2, 3, 4, 5].map(r => ({
    rating: `${r}★`,
    count:  ratingDistribution.find(rd => rd.rating === r)?._count.id || 0,
  }));

  // Report categories
  const reportCats = reportsByCategory.map(r => ({
    category: r.category,
    count:    r._count.id,
  }));

  const reportResolutionRate = totalReports > 0
    ? Math.round((resolvedReports / totalReports) * 100) : 0;

  const ticketResolutionRate = totalTickets > 0
    ? Math.round((resolvedTickets / totalTickets) * 100) : 0;

  return {
    chat: {
      totalMessages,
      totalChats,
      avgMessagesPerChat: totalChats > 0
        ? Math.round(totalMessages / totalChats) : 0,
    },
    reviews: {
      totalReviews,
      avgRating:         Math.round((avgRating._avg?.rating || 0) * 10) / 10,
      ratingDistribution: ratingDist,
    },
    reports: {
      totalReports,
      resolvedReports,
      reportResolutionRate,
      byCategory: reportCats,
    },
    support: {
      totalTickets,
      resolvedTickets,
      ticketResolutionRate,
      avgResolutionHours,
    },
  };
}

/**
 * Function 7: getGeographyAnalytics()
 * Returns platform adoption by country and region.
 */
async function getGeographyAnalytics() {
  const [
    usersByCountry,
    listingsByCountry,
    bookingValueByCountry,
  ] = await Promise.all([
    prisma.user.groupBy({
      by: ['country'],
      where: { role: 'USER', country: { not: null } },
      _count: { id: true },
      orderBy: { _count: { id: 'desc' } },
      take: 20,
    }),
    prisma.listing.groupBy({
      by: ['country'],
      where: { status: 'ACTIVE', country: { not: null } },
      _count: { id: true },
      orderBy: { _count: { id: 'desc' } },
      take: 20,
    }),
    prisma.booking.findMany({
      where: { status: { in: ['ACCEPTED', 'COMPLETED'] } },
      select: {
        totalPrice: true,
        listing: { select: { country: true } },
      },
    }),
  ]);

  // Combine into country table
  const countryData = {};

  usersByCountry.forEach(u => {
    if (u.country) {
      countryData[u.country] = countryData[u.country] || {
        country: u.country, users: 0, listings: 0, revenue: 0
      };
      countryData[u.country].users = u._count.id;
    }
  });

  listingsByCountry.forEach(l => {
    if (l.country) {
      countryData[l.country] = countryData[l.country] || {
        country: l.country, users: 0, listings: 0, revenue: 0
      };
      countryData[l.country].listings = l._count.id;
    }
  });

  bookingValueByCountry.forEach(b => {
    const c = b.listing?.country;
    if (c) {
      countryData[c] = countryData[c] || {
        country: c, users: 0, listings: 0, revenue: 0
      };
      countryData[c].revenue += (b.totalPrice || 0);
    }
  });

  const countryTable = Object.values(countryData)
    .map(c => ({ ...c, revenue: Math.round(c.revenue) }))
    .sort((a, b) => b.users - a.users);

  return { countryTable };
}

/**
 * Function 8: getCategoryAnalytics()
 * Returns category performance comparison.
 */
async function getCategoryAnalytics() {
  const categories = await prisma.category.findMany({
    include: {
      _count: { select: { listings: true } },
    },
  });

  const categoryIds = categories.map(c => c.id);

  const [bookingCounts, avgPrices, reviewRatings] = await Promise.all([
    prisma.booking.groupBy({
      by: ['listingId'],
      _count: { id: true },
    }),
    prisma.listing.groupBy({
      by: ['categoryId'],
      where: { status: 'ACTIVE' },
      _avg: { pricePerDay: true },
    }),
    prisma.review.findMany({
      include: {
        listing: { select: { categoryId: true } },
      },
      select: { rating: true, listing: { select: { categoryId: true } } },
    }),
  ]);

  // Build category performance table
  const avgPriceMap = Object.fromEntries(
    avgPrices.map(p => [p.categoryId, Math.round(p._avg?.pricePerDay || 0)])
  );

  // Avg rating per category
  const catRatings = {};
  const catRatingCounts = {};
  reviewRatings.forEach(r => {
    const cId = r.listing?.categoryId;
    if (cId) {
      catRatings[cId]      = (catRatings[cId] || 0) + r.rating;
      catRatingCounts[cId] = (catRatingCounts[cId] || 0) + 1;
    }
  });

  const categoryPerformance = categories.map(cat => ({
    id:           cat.id,
    name:         cat.name,
    icon:         cat.icon,
    totalListings: cat._count.listings,
    avgPrice:     avgPriceMap[cat.id] || 0,
    avgRating:    catRatingCounts[cat.id]
      ? Math.round((catRatings[cat.id] / catRatingCounts[cat.id]) * 10) / 10
      : 0,
    reviewCount:  catRatingCounts[cat.id] || 0,
  })).sort((a, b) => b.totalListings - a.totalListings);

  return { categoryPerformance };
}

module.exports = {
  getOverview,
  getUserAnalytics,
  getListingAnalytics,
  getBookingAnalytics,
  getRevenueAnalytics,
  getEngagementAnalytics,
  getGeographyAnalytics,
  getCategoryAnalytics,
};
