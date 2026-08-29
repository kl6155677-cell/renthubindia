const prisma = require('../../config/db');

/**
 * Calculates new average ratings and pushes them into User and Listing tables.
 */
const updateAverageRatings = async (userId, listingId) => {
  // Update User Rating
  const userAggregate = await prisma.review.aggregate({
    where: { revieweeId: userId },
    _avg: { rating: true },
  });

  if (userAggregate._avg.rating !== null) {
    await prisma.user.update({
      where: { id: userId },
      data: { rating: userAggregate._avg.rating }
    });
  }

  // Update Listing Rating
  const [listingAggregate, reviewCount] = await Promise.all([
    prisma.review.aggregate({
      where: { listingId: listingId },
      _avg: { rating: true },
    }),
    prisma.review.count({
      where: { listingId: listingId }
    })
  ]);

  if (listingAggregate._avg.rating !== null) {
    await prisma.listing.update({
      where: { id: listingId },
      data: { 
        rating: listingAggregate._avg.rating,
        reviewCount: reviewCount
      }
    });
  }
};

const submitReview = async (reviewerId, data) => {
  const { bookingId, rating, comment } = data;

  const booking = await prisma.booking.findUnique({
    where: { id: bookingId }
  });

  if (!booking) throw new Error('Booking not found');
  if (booking.status !== 'COMPLETED') throw new Error('You can only review completed bookings');
  if (booking.renterId !== reviewerId) {
    throw new Error('Only the renter can leave a review for this transaction');
  }

  // Check if a review already exists for this exact booking. 
  // Prisma unique constraints handle this, but explicit catching helps API responses.
  const existingReview = await prisma.review.findUnique({ where: { bookingId } });
  if (existingReview) {
    throw new Error('A review has already been submitted for this booking');
  }

  // Determine the target (If Renter is reviewing, Owner is target. If Owner is reviewing, Renter is target)
  const revieweeId = booking.renterId === reviewerId ? booking.ownerId : booking.renterId;

  const newReview = await prisma.review.create({
    data: {
      bookingId,
      listingId: booking.listingId,
      reviewerId,
      revieweeId,
      rating,
      comment
    }
  });

  // Calculate new averages mathematically and push back onto User and Listing
  await updateAverageRatings(revieweeId, booking.listingId);

  return newReview;
};

const { paginate } = require('../../utils/paginate');

const getListingReviews = async (listingId, { page, limit }) => {
  return paginate({
    modelName: 'review',
    where:     { listingId },
    include:   { reviewer: { select: { id: true, name: true, avatarUrl: true } } },
    orderBy:   { createdAt: 'desc' },
    page,
    limit,
  });
};

const getUserReviews = async (userId, { page, limit }) => {
  return paginate({
    modelName: 'review',
    where:     { revieweeId: userId },
    include:   {
      reviewer: { select: { id: true, name: true, avatarUrl: true } },
      listing:  { select: { id: true, title: true } },
    },
    orderBy:   { createdAt: 'desc' },
    page,
    limit,
  });
};

module.exports = {
  submitReview,
  getListingReviews,
  getUserReviews
};
