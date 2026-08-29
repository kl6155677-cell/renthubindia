const prisma = require('../../config/db');
const { getIO } = require('../../config/socket');
const { sendNotification } = require('../../utils/notifications');

const createBooking = async (renterId, data) => {
  const { listingId, startDate, endDate } = data;
  const start = new Date(startDate);
  const end = new Date(endDate);

  // 1. Basic Date Validation
  if (isNaN(start.getTime()) || isNaN(end.getTime())) throw new Error('Invalid dates provided');
  if (start >= end) throw new Error('End date must be after start date');
  
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  if (start < today) throw new Error('Cannot book dates in the past');

  const listing = await prisma.listing.findUnique({
    where: { id: listingId },
    include: { user: { select: { id: true, name: true, fcmToken: true } } }
  });

  if (!listing) throw new Error('Listing not found');
  if (!listing.isApproved || listing.status !== 'ACTIVE') throw new Error('Listing is currently unavailable for rent');
  if (listing.userId === renterId) throw new Error('You cannot book your own listing');

  // Check if dates are within listing's general availability
  if (listing.availableFrom && start < new Date(listing.availableFrom)) {
    throw new Error(`Listing is only available from ${listing.availableFrom.toDateString()}`);
  }
  if (listing.availableTo && end > new Date(listing.availableTo)) {
    throw new Error(`Listing is only available until ${listing.availableTo.toDateString()}`);
  }

  // 2. Overlap check (Blocked by PENDING or ACCEPTED bookings)
  const overlapping = await prisma.booking.findFirst({
    where: {
      listingId,
      status: { in: ['PENDING', 'ACCEPTED'] },
      OR: [
        { startDate: { lt: end }, endDate: { gt: start } }
      ]
    }
  });

  if (overlapping) throw new Error('Selected dates are already booked. Please choose different dates.');

  // 3. Calculate pricing (Minimum 1 day)
  const diffTime = Math.abs(end - start);
  const diffDays = Math.max(1, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
  const totalPrice = Number(listing.pricePerDay) * diffDays;

  const renter = await prisma.user.findUnique({ where: { id: renterId }, select: { name: true } });

  const booking = await prisma.booking.create({
    data: {
      listingId,
      renterId,
      ownerId: listing.userId,
      startDate: start,
      endDate: end,
      totalPrice,
      notes: data.notes,
      status: 'PENDING'
    }
  });

  // Notify Owner
  const io = getIO();
  sendNotification(io, {
    userId: listing.userId,
    title: 'New Booking Request! 📦',
    body: `${renter.name} wants to rent your "${listing.title}" for ${diffDays} day${diffDays > 1 ? 's' : ''}`,
    type: 'booking_update',
    data: { bookingId: booking.id, listingId: booking.listingId },
    fcmToken: listing.user?.fcmToken,
  });

  // Notify Renter (Confirmation)
  sendNotification(io, {
    userId: renterId,
    title: 'Booking Request Sent! 📤',
    body: `Your request for "${listing.title}" has been sent to the owner.`,
    type: 'booking_update',
    data: { bookingId: booking.id, listingId: booking.listingId },
  });

  return booking;
};

const { paginate } = require('../../utils/paginate');

const getMyBookings = async (renterId, { status, page, limit }) => {
  const where = { renterId };
  if (status) where.status = status;

  return paginate({
    modelName: 'booking',
    where,
    include: {
      listing: {
        select: {
          id: true,
          title: true,
          pricePerDay: true,
          images: { take: 1, select: { imageUrl: true } },
        },
      },
      owner: { select: { id: true, name: true, avatarUrl: true, rating: true } },
    },
    page,
    limit,
  });
};

const getIncomingBookings = async (ownerId, { status, page, limit }) => {
  const where = { ownerId };
  if (status) where.status = status;

  return paginate({
    modelName: 'booking',
    where,
    include: {
      listing: {
        select: {
          id: true,
          title: true,
          pricePerDay: true,
          images: { take: 1, select: { imageUrl: true } },
        },
      },
      renter: { select: { id: true, name: true, avatarUrl: true, rating: true } },
    },
    page,
    limit,
  });
};

const acceptBooking = async (ownerId, bookingId) => {
  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
    include: { renter: { select: { id: true, name: true, fcmToken: true } }, listing: true }
  });

  if (!booking) throw new Error('Booking not found');
  if (booking.ownerId !== ownerId) throw new Error('Unauthorized');
  if (booking.status !== 'PENDING') throw new Error('Only PENDING bookings can be accepted');

  const updatedBooking = await prisma.booking.update({
    where: { id: bookingId },
    data: { status: 'ACCEPTED' }
  });

  // ── AUTO-REJECT OVERLAPPING PENDING REQUESTS ─────────────────
  // Find other requests for this listing that overlap and are still pending
  const overlaps = await prisma.booking.findMany({
    where: {
      id: { not: bookingId },
      listingId: booking.listingId,
      status: 'PENDING',
      OR: [
        { startDate: { lt: booking.endDate }, endDate: { gt: booking.startDate } }
      ]
    },
    include: { renter: { select: { fcmToken: true } } }
  });

  if (overlaps.length > 0) {
    const io = getIO();
    for (const overlap of overlaps) {
      await prisma.booking.update({
        where: { id: overlap.id },
        data: { status: 'CANCELLED' }
      });

      // Notify these renters that the dates were taken
      sendNotification(io, {
        userId: overlap.renterId,
        title: 'Dates Unavailable 😔',
        body: `The listing "${booking.listing.title}" was booked by someone else for your selected dates.`,
        type: 'booking_update',
        data: { bookingId: overlap.id, listingId: overlap.listingId },
        fcmToken: overlap.renter?.fcmToken,
      });
    }
  }

  // Notify the accepted RENTER
  const io = getIO();
  sendNotification(io, {
    userId: booking.renterId,
    title: 'Booking Accepted! 🎉',
    body: `Your booking for "${booking.listing.title}" has been accepted`,
    type: 'booking_update',
    data: { bookingId: updatedBooking.id, listingId: booking.listingId },
    fcmToken: booking.renter?.fcmToken,
  });

  return updatedBooking;
};

const cancelBooking = async (userId, bookingId) => {
  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
    include: { renter: true, owner: true, listing: true }
  });

  if (!booking) throw new Error('Booking not found');
  if (booking.renterId !== userId && booking.ownerId !== userId) throw new Error('Unauthorized');

  if (['COMPLETED', 'CANCELLED'].includes(booking.status)) throw new Error('Booking cannot be cancelled from its current state');

  const updatedBooking = await prisma.booking.update({
    where: { id: bookingId },
    data: { status: 'CANCELLED' }
  });

  const isOwnerCancelling = booking.ownerId === userId;
  const recipientId = isOwnerCancelling ? booking.renterId : booking.ownerId;
  const triggerRole = isOwnerCancelling ? 'Owner' : 'Renter';

  const io = getIO();
  sendNotification(io, {
    userId: recipientId,
    title: 'Booking Cancelled ❌',
    body: `The ${triggerRole} has cancelled the booking for "${booking.listing.title}"`,
    type: 'booking_update',
    data: { bookingId: updatedBooking.id, listingId: booking.listingId },
  });

  return updatedBooking;
};

const completeBooking = async (ownerId, bookingId) => {
  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
    include: { renter: true, listing: true }
  });

  if (!booking) throw new Error('Booking not found');
  if (booking.ownerId !== ownerId) throw new Error('Unauthorized');
  
  if (booking.status !== 'ACCEPTED') throw new Error('Booking is not ready to be completed');

  const updatedBooking = await prisma.booking.update({
    where: { id: bookingId },
    data: { status: 'COMPLETED' }
  });

  const io = getIO();
  sendNotification(io, {
    userId: booking.renterId,
    title: 'Rental Completed! 🏁',
    body: `How was your rental for "${booking.listing.title}"? please leave a review!`,
    type: 'booking_update',
    data: { bookingId: updatedBooking.id, listingId: booking.listingId },
  });

  return updatedBooking;
};

module.exports = {
  createBooking,
  getMyBookings,
  getIncomingBookings,
  acceptBooking,
  cancelBooking,
  completeBooking
};
