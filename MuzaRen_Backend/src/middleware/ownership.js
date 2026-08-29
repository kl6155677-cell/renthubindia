const prisma = require('../config/db');

// Check that the authenticated user owns the listing
async function requireListingOwner(req, res, next) {
  try {
    const listingId = req.params.id || req.params.listingId;
    if (!listingId) {
      return res.status(400).json({ success: false, message: 'Listing ID required' });
    }

    const listing = await prisma.listing.findUnique({
      where: { id: listingId },
      select: { userId: true },
    });

    if (!listing) {
      return res.status(404).json({ success: false, message: 'Listing not found' });
    }

    if (listing.userId !== req.user.id) {
      return res.status(403).json({ success: false, message: 'You do not own this listing' });
    }

    next();
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Authorization check failed' });
  }
}

// Check that the user is involved in the booking (owner or renter)
async function requireBookingParticipant(req, res, next) {
  try {
    const bookingId = req.params.id;
    if (!bookingId) {
      return res.status(400).json({ success: false, message: 'Booking ID required' });
    }

    const booking = await prisma.booking.findUnique({
      where: { id: bookingId },
      select: { renterId: true, ownerId: true },
    });

    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    if (booking.renterId !== req.user.id && booking.ownerId !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized to access this booking' });
    }

    req.booking = booking; // Optimization: attach to request so controller doesn't need to fetch again
    next();
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Authorization check failed' });
  }
}

module.exports = { requireListingOwner, requireBookingParticipant };
