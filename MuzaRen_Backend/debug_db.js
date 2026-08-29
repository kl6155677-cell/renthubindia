const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const prisma = require('./src/config/db');

async function debug() {
  const total = await prisma.listing.count();
  const activeAndApproved = await prisma.listing.count({
    where: {
      status: 'ACTIVE',
      isApproved: true
    }
  });

  const samples = await prisma.listing.findMany({
    take: 5,
    select: {
      title: true,
      country: true,
      city: true,
      status: true,
      isApproved: true
    }
  });

  console.log('--- DATABASE DEBUG ---');
  console.log('Total Listings:', total);
  console.log('Active & Approved:', activeAndApproved);
  console.log('Sample Data:', JSON.stringify(samples, null, 2));
}

debug().finally(() => prisma.$disconnect());
