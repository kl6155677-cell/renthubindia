const prisma = require('../../config/db');
const { normalizeCountry, normalizeCity } = require('../../utils/location');

const { paginate } = require('../../utils/paginate');

const browseListings = async (filters) => {
  const { userId, category, country, city, search, priceMin, priceMax, sortBy, page, limit } = filters;
  
  // Normalize search filters
  const normalizedCountry = normalizeCountry(country);
  const normalizedCity = normalizeCity(city);

  const where = {
    status: 'ACTIVE',
    ...(process.env.NODE_ENV === 'production' ? { isApproved: true } : {}),
  };

  if (userId) where.userId = userId;
  if (category) where.category = { slug: category };
  if (normalizedCountry) where.country = { contains: normalizedCountry, mode: 'insensitive' };
  if (normalizedCity) where.city = { contains: normalizedCity, mode: 'insensitive' };
  
  // Text search on title or description
  if (search) {
    where.OR = [
      { title: { contains: search, mode: 'insensitive' } },
      { description: { contains: search, mode: 'insensitive' } }
    ];
  }

  if (priceMin || priceMax) {
    where.pricePerDay = {};
    if (priceMin) where.pricePerDay.gte = parseFloat(priceMin);
    if (priceMax) where.pricePerDay.lte = parseFloat(priceMax);
  }

  // Sorting logic
  let orderBy = { createdAt: 'desc' }; // default: newest
  if (sortBy === 'price_asc') orderBy = { pricePerDay: 'asc' };
  if (sortBy === 'price_desc') orderBy = { pricePerDay: 'desc' };
  if (sortBy === 'rating') orderBy = { rating: 'desc' };

  return paginate({
    modelName: 'listing',
    where,
    include: {
      images: {
        orderBy: { sortOrder: 'asc' },
        take: 1,
        select: { imageUrl: true, sortOrder: true }
      },
      category: { select: { id: true, name: true, icon: true } },
      user: { select: { id: true, name: true, avatarUrl: true, rating: true, verificationStatus: true } }
    },
    orderBy,
    page,
    limit,
  });
};

const getListingById = async (id) => {
  const listing = await prisma.listing.findUnique({
    where: { id },
    include: {
      images: { orderBy: { sortOrder: 'asc' } },
      category: { select: { name: true, icon: true, slug: true } },
      user: {
        select: {
          id: true,
          name: true,
          avatarUrl: true,
          rating: true,
          verificationStatus: true,
          createdAt: true
        }
      },
      bookings: {
        where: {
          status: { in: ['PENDING', 'ACCEPTED'] }
        },
        select: {
          startDate: true,
          endDate: true
        }
      }
    }
  });

  if (!listing) throw new Error('Listing not found');
  if (listing.status !== 'ACTIVE' && listing.status !== 'PAUSED') throw new Error('Listing is unavailable');

  return listing;
};

const createListing = async (userId, data, userProfile) => {
  // Business logic: items over $1000/day require verified account
  if (data.pricePerDay > 1000 && userProfile.verificationStatus !== 'VERIFIED') {
    throw new Error('High value items require a VERIFIED account status');
  }

  // Normalize location inputs
  const country = normalizeCountry(data.country || userProfile.country);
  const city = normalizeCity(data.city || userProfile.city);

  // Security Hardening: Only allow specific fields
  const allowedFields = ['title', 'description', 'pricePerDay', 'categoryId', 'location', 'latitude', 'longitude', 'country', 'city', 'availableFrom', 'availableTo'];
  const filteredData = Object.keys(data)
    .filter(key => allowedFields.includes(key))
    .reduce((obj, key) => {
      obj[key] = data[key];
      return obj;
    }, {});

  const newListing = await prisma.listing.create({
    data: {
      ...filteredData,
      userId,
      country,
      city,
      isApproved: true // Auto-approved — re-enable admin gate when admin panel is ready
    }
  });

  return newListing;
};

const updateListing = async (userId, listingId, data) => {
  const listing = await prisma.listing.findUnique({ where: { id: listingId } });
  
  if (!listing) throw new Error('Listing not found');
  if (listing.userId !== userId) throw new Error('Unauthorized ownership');

  // Security Hardening: Only allow specific fields
  const allowedFields = ['title', 'description', 'pricePerDay', 'categoryId', 'location', 'latitude', 'longitude', 'country', 'city', 'availableFrom', 'availableTo', 'status'];
  const filteredData = Object.keys(data)
    .filter(key => allowedFields.includes(key))
    .reduce((obj, key) => {
      obj[key] = data[key];
      return obj;
    }, {});

  // Any edits default to re-requiring admin approval for safety guidelines
  const updatedListing = await prisma.listing.update({
    where: { id: listingId },
    data: { ...filteredData, isApproved: false }
  });

  return updatedListing;
};

const deleteListing = async (userId, listingId) => {
  const listing = await prisma.listing.findUnique({ 
    where: { id: listingId },
    include: { bookings: { where: { status: { in: ['ACCEPTED'] } } } }
  });
  
  if (!listing) throw new Error('Listing not found');
  if (listing.userId !== userId) throw new Error('Unauthorized ownership');

  // Block deletion if there are active bookings involving this listing
  if (listing.bookings.length > 0) {
    throw new Error('Cannot delete a listing that has active or confirmed bookings. Please complete or cancel them first.');
  }

  // Database Cascade will handle images, reports, reviews, and chats
  await prisma.listing.delete({ where: { id: listingId } });

  return { message: 'Listing permanently deleted' };
};

const updateListingStatus = async (userId, listingId, status) => {
  const listing = await prisma.listing.findUnique({ where: { id: listingId } });
  
  if (!listing) throw new Error('Listing not found');
  if (listing.userId !== userId) throw new Error('Unauthorized ownership');

  const updatedListing = await prisma.listing.update({
    where: { id: listingId },
    data: { status }
  });

  return updatedListing;
};

const getMyListings = async (userId, { page, limit }) => {
  return paginate({
    modelName: 'listing',
    where: { userId },
    include: {
      images: { orderBy: { sortOrder: 'asc' }, take: 1, select: { imageUrl: true } },
      category: { select: { id: true, name: true, icon: true } }
    },
    orderBy: { createdAt: 'desc' },
    page,
    limit,
  });
};

const uploadListingImages = async (userId, listingId, files) => {
  const listing = await prisma.listing.findUnique({ where: { id: listingId } });
  
  if (!listing) throw new Error('Listing not found');
  if (listing.userId !== userId) throw new Error('Unauthorized ownership');
  if (!files || files.length === 0) throw new Error('No files provided');

  const imageRecords = files.map((file, index) => ({
    listingId,
    imageUrl: file.path,
    sortOrder: index
  }));

  await prisma.listingImage.createMany({
    data: imageRecords
  });

  return { message: 'Images successfully uploaded' };
};

module.exports = {
  browseListings,
  getListingById,
  createListing,
  updateListing,
  deleteListing,
  updateListingStatus,
  getMyListings,
  uploadListingImages
};
