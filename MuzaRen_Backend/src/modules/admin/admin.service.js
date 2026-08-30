const prisma = require('../../config/db');
const { getIO } = require('../../config/socket');
const { sendNotification } = require('../../utils/notifications');
const { toSlug } = require('./admin.validation');
const { paginate } = require('../../utils/paginate');
const { getStartDate, getPreviousPeriodStart, calculateGrowth, groupByPeriod } = require('../../utils/analyticsHelpers');

// ─── DASHBOARD ────────────────────────────────────────────────────────────────

const getDashboardStats = async () => {
  const startDate7d = getStartDate('7d');
  const startDate30d = getStartDate('30d');
  const prevStart30d = getPreviousPeriodStart('30d');

  const [
    totalUsers,
    newUsers30d,
    prevUsers30d,
    totalListings,
    newListings30d,
    prevListings30d,
    totalBookings,
    newBookings30d,
    prevBookings30d,
    openReports,
    pendingVerifications,
    openSupportTickets,
    recentActivityData,
  ] = await Promise.all([
    prisma.user.count(),
    prisma.user.count({ where: { role: 'USER', createdAt: { gte: startDate30d } } }),
    prisma.user.count({ where: { role: 'USER', createdAt: { gte: prevStart30d, lt: startDate30d } } }),
    prisma.listing.count(),
    prisma.listing.count({ where: { createdAt: { gte: startDate30d } } }),
    prisma.listing.count({ where: { createdAt: { gte: prevStart30d, lt: startDate30d } } }),
    prisma.booking.count(),
    prisma.booking.count({ where: { createdAt: { gte: startDate30d } } }),
    prisma.booking.count({ where: { createdAt: { gte: prevStart30d, lt: startDate30d } } }),
    prisma.report.count({ where: { status: 'OPEN' } }),
    prisma.user.count({ where: { verificationStatus: 'PENDING' } }),
    prisma.supportTicket.count({ where: { status: 'OPEN' } }),
    prisma.booking.findMany({
      where: { createdAt: { gte: startDate7d } },
      select: { createdAt: true },
      orderBy: { createdAt: 'asc' },
    }),
  ]);


  // Group bookings by day for the last 7 days
  const recentActivity = groupByPeriod(recentActivityData, 'createdAt', '7d');

  return {
    totalUsers,
    totalListings,
    totalBookings,
    openReports,
    pendingVerifications,
    openSupportTickets,
    recentActivity,
    newUsers7d: newUsers30d, // Using 30d for the "new" count displayed in cards usually
    userGrowth: calculateGrowth(newUsers30d, prevUsers30d),
    listingGrowth: calculateGrowth(newListings30d, prevListings30d),
    bookingGrowth: calculateGrowth(newBookings30d, prevBookings30d),
  };
};

// ─── USERS ────────────────────────────────────────────────────────────────────

const approveVerification = async (userId) => {
  const user = await prisma.user.update({
    where: { id: userId },
    data: { verificationStatus: 'VERIFIED' },
  });

  const io = getIO();
  await sendNotification(io, {
    userId: user.id,
    title: 'Identity Verified ✓',
    body: 'Your account has been verified. You can now post high-value items!',
    type: 'verification',
    data: {},
  });

  return user;
};

// ─── LISTINGS ─────────────────────────────────────────────────────────────────

const listAllListings = async ({ search, category, status, page, limit }) => {
  const where = {};
  if (search) {
    where.OR = [
      { title: { contains: search, mode: 'insensitive' } },
      { description: { contains: search, mode: 'insensitive' } },
    ];
  }
  if (category) where.categoryId = category;
  if (status)   where.status     = status;

  return paginate({
    modelName: 'listing',
    where,
    include: {
      user:     { select: { id: true, name: true, email: true } },
      category: { select: { id: true, name: true } },
      images:   { select: { imageUrl: true }, take: 1 },
    },
    orderBy: { createdAt: 'desc' },
    page,
    limit,
  });
};

const approveListing = async (listingId, isApproved) => {
  const listing = await prisma.listing.update({
    where: { id: listingId },
    data: { isApproved },
    include: { user: true },
  });

  const io = getIO();
  if (isApproved) {
    await sendNotification(io, {
      userId: listing.userId,
      title: 'Listing Approved',
      body: `Your listing "${listing.title}" is now actively live!`,
      type: 'system',
      data: { listingId: listing.id },
    });
  }

  return listing;
};

const deleteListing = async (listingId) => {
  await prisma.listingImage.deleteMany({ where: { listingId } });
  await prisma.review.deleteMany({ where: { listingId } });
  await prisma.booking.deleteMany({ where: { listingId } });
  return await prisma.listing.delete({ where: { id: listingId } });
};

// ─── BOOKINGS ─────────────────────────────────────────────────────────────────

const listAllBookings = async ({ status, page, limit }) => {
  const where = {};
  if (status) where.status = status;

  return paginate({
    modelName: 'booking',
    where,
    include: {
      listing: { select: { id: true, title: true, city: true, country: true } },
      renter:  { select: { id: true, name: true, email: true } },
      owner:   { select: { id: true, name: true, email: true } },
    },
    orderBy: { createdAt: 'desc' },
    page,
    limit,
  });
};

// ─── REPORTS ─────────────────────────────────────────────────────────────────

const listReports = async ({ status, targetType, category, page, limit }) => {
  const where = {};
  if (status)     where.status     = status;
  if (targetType) where.targetType = targetType;
  if (category)   where.category   = category;

  return paginate({
    modelName: 'report',
    where,
    include: {
      reporter:     { select: { id: true, name: true, avatarUrl: true } },
      targetListing:{ select: { id: true, title: true } },
      targetUser:   { select: { id: true, name: true } },
    },
    page,
    limit,
  });
};

const actionReport = async (reportId, status, adminNote) => {
  const report = await prisma.report.update({
    where: { id: reportId },
    data: { status, ...(adminNote ? { adminNote } : {}) },
    include: { reporter: true },
  });

  if (status === 'RESOLVED') {
    const io = getIO();
    await sendNotification(io, {
      userId: report.reporterId,
      title: 'Report Resolved',
      body: 'We have investigated and resolved your submitted report. Thank you.',
      type: 'system',
      data: { reportId: report.id },
    });
  }

  return report;
};

// ─── REVIEWS ─────────────────────────────────────────────────────────────────

const listAllReviews = async ({ page, limit }) => {
  return paginate({
    modelName: 'review',
    include: {
      reviewer: { select: { id: true, name: true, email: true } },
      reviewee: { select: { id: true, name: true, email: true } },
    },
    orderBy: { createdAt: 'desc' },
    page,
    limit,
  });
};

const deleteReview = async (reviewId) => {
  const review = await prisma.review.delete({ where: { id: reviewId } });
  const { updateAverageUserRating } = require('../reviews/reviews.service');
  await updateAverageUserRating(review.revieweeId);
  return review;
};

// ─── SUPPORT TICKETS ──────────────────────────────────────────────────────────

const listAllTickets = async ({ status, search, page, limit }) => {
  const where = {};
  if (status) where.status = status;
  if (search) where.subject = { contains: search, mode: 'insensitive' };

  return paginate({
    modelName: 'supportTicket',
    where,
    include: { user: { select: { id: true, name: true, email: true } } },
    orderBy: { createdAt: 'asc' }, // oldest first for SLA
    page,
    limit,
  });
};

const replyToTicket = async (ticketId, adminReply) => {
  const ticket = await prisma.supportTicket.update({
    where: { id: ticketId },
    data: { adminReply, status: 'RESOLVED' },
    include: { user: true },
  });

  const io = getIO();
  await sendNotification(io, {
    userId: ticket.userId,
    title: 'Support Ticket Update',
    body: `An admin has replied to your support ticket: "${ticket.subject}"`,
    type: 'system',
    data: { ticketId: ticket.id },
  });

  return ticket;
};

// ─── CATEGORIES ──────────────────────────────────────────────────────────────

const listCategories = async ({ search, page, limit }) => {
  const where = {};
  if (search) where.name = { contains: search, mode: 'insensitive' };

  // For categories, also get listing count per category
  const { data, pagination } = await paginate({
    modelName: 'category',
    where,
    orderBy:   { name: 'asc' },
    page,
    limit,
  });

  // Attach listing count to each category
  const dataWithCount = await Promise.all(
    data.map(async (cat) => ({
      ...cat,
      listingCount: await prisma.listing.count({
        where: { categoryId: cat.id, status: 'ACTIVE' },
      }),
    }))
  );

  return { data: dataWithCount, pagination };
};

const createCategory = async (data) => {
  // 'description' does not exist in Category schema — strip it
  // 'icon' is required — default to generic emoji if not sent by UI
  // 'slug' is required + unique — auto-generate from name if not provided
  const { description: _desc, ...rest } = data;
  const slug = rest.slug || toSlug(rest.name);
  const icon = rest.icon || '📦';
  return await prisma.category.create({ data: { ...rest, slug, icon } });
};

const updateCategory = async (id, data) => {
  // Strip description (not in schema), regenerate slug if name changed
  const { description: _desc, ...rest } = data;
  const updateData = { ...rest };
  if (rest.name && !rest.slug) updateData.slug = toSlug(rest.name);
  return await prisma.category.update({ where: { id }, data: updateData });
};

const deleteCategory = async (id) => {
  return await prisma.category.delete({ where: { id } });
};

// ─── MESSAGING MODERATION ───────────────────────────────────────────────────

const listFlaggedMessages = async ({ page, limit }) => {
  return paginate({
    modelName: 'message',
    where: { isFlagged: true },
    include: {
      sender:   { select: { id: true, name: true, email: true } },
      receiver: { select: { id: true, name: true, email: true } },
    },
    orderBy: { createdAt: 'desc' },
    page,
    limit,
  });
};

const deleteMessage = async (messageId, reason) => {
  // Logic to log deletion reason could go here
  return await prisma.message.delete({ where: { id: messageId } });
};

// ─── BROADCASTS ─────────────────────────────────────────────────────────────

const listBroadcasts = async ({ page, limit }) => {
  return paginate({
    modelName: 'broadcast',
    orderBy: { createdAt: 'desc' },
    page,
    limit,
  });
};

const sendBroadcast = async (data) => {
  const broadcast = await prisma.broadcast.create({
    data: {
      ...data,
      status: 'SENT',
    }
  });

  // Real implementation would trigger FCM/Push logic here
  return broadcast;
};

// ─── ANALYTICS ──────────────────────────────────────────────────────────────

const getAnalytics = async (range = '30d') => {
  // Mocking analytics data since real aggregation requires complex raw queries
  // In production, this would use prisma.$queryRaw or a warehouse sync
  return {
    userGrowth: Array.from({ length: 7 }).map((_, i) => ({
      date: new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString(),
      count: Math.floor(Math.random() * 50) + 10
    })),
    listingGrowth: Array.from({ length: 7 }).map((_, i) => ({
      date: new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString(),
      count: Math.floor(Math.random() * 20) + 5
    })),
    bookingFunnel: {
      created: 100,
      accepted: 80,
      completed: 65,
      cancelled: 15
    },
    topCategories: [
      { categoryName: 'Electronics', listingCount: 450 },
      { categoryName: 'Tools', listingCount: 320 },
      { categoryName: 'Cars', listingCount: 280 }
    ],
    geoDemand: [
      { city: 'Casablanca', country: 'Morocco', listingCount: 1200 },
      { city: 'Rabat', country: 'Morocco', listingCount: 800 },
      { city: 'Marrakech', country: 'Morocco', listingCount: 500 }
    ]
  };
};

const listCities = async () => {
  return await prisma.serviceableCity.findMany({
    orderBy: { name: 'asc' }
  });
};

const createCity = async (data) => {
  return await prisma.serviceableCity.create({
    data: { name: data.name, isActive: data.isActive }
  });
};

const updateCity = async (id, data) => {
  return await prisma.serviceableCity.update({
    where: { id },
    data: { name: data.name, isActive: data.isActive }
  });
};

const deleteCity = async (id) => {
  return await prisma.serviceableCity.delete({
    where: { id }
  });
};

module.exports = {
  getDashboardStats,
  approveVerification,
  listAllListings, approveListing, deleteListing,
  listAllBookings,
  listReports, actionReport,
  listAllReviews, deleteReview,
  listAllTickets, replyToTicket,
  listCategories, createCategory, updateCategory, deleteCategory,
  listFlaggedMessages, deleteMessage,
  listBroadcasts, sendBroadcast,
  getAnalytics,
  listCities, createCity, updateCity, deleteCity
};
