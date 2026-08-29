const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const prisma = require('./src/config/db');

async function fix() {
  console.log('🛠️ Starting Data Consistency Repair...');

  // 1. Approve ALL listings currently in the database
  const approvedCount = await prisma.listing.updateMany({
    data: {
      isApproved: true,
      status: 'ACTIVE'
    }
  });
  console.log(`✅ Approved ${approvedCount.count} listings.`);

  // 2. Standardize Country Names
  const mappings = [
    { from: 'US', to: 'United States' },
    { from: 'IN', to: 'India' },
    { from: 'SG', to: 'Singapore' },
    { from: 'GB', to: 'United Kingdom' },
    { from: 'TR', to: 'Turkey' },
    { from: 'AE', to: 'United Arab Emirates' },
    { from: 'QA', to: 'Qatar' },
    { from: 'SA', to: 'Saudi Arabia' },
    { from: 'FR', to: 'France' },
    { from: 'MA', to: 'Morocco' },
    { from: 'india', to: 'India' },
    { from: 'singapore', to: 'Singapore' },
    { from: 'usa', to: 'United States' },
    { from: 'NYC', to: 'United States' } // Some city names were in country field
  ];

  for (const map of mappings) {
    const res = await prisma.listing.updateMany({
      where: {
        country: {
          equals: map.from,
          mode: 'insensitive'
        }
      },
      data: {
        country: map.to
      }
    });
    if (res.count > 0) {
      console.log(`🌍 Mapped ${res.count} listings from "${map.from}" to "${map.to}"`);
    }
  }

  // 3. Final Check
  const total = await prisma.listing.count();
  const activeAndApproved = await prisma.listing.count({
    where: { status: 'ACTIVE', isApproved: true }
  });

  console.log('\n--- Repair Summary ---');
  console.log(`Total Listings: ${total}`);
  console.log(`Ready for Display: ${activeAndApproved}`);
  console.log('-----------------------');
}

fix()
  .catch(e => console.error('❌ Repair failed:', e))
  .finally(() => prisma.$disconnect());
