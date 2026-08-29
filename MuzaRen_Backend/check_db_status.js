const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const allListings = await prisma.listing.count();
    const approvedListings = await prisma.listing.count({
      where: {
        status: 'ACTIVE',
        isApproved: true,
      },
    });
    const unapprovedListings = await prisma.listing.count({
      where: {
        isApproved: false,
      },
    });

    console.log('--- DB Status ---');
    console.log(`Total Listings: ${allListings}`);
    console.log(`Approved & Active: ${approvedListings}`);
    console.log(`Unapproved: ${unapprovedListings}`);
    
    if (allListings > 0) {
      const sample = await prisma.listing.findFirst({
        include: { category: true, user: true }
      });
      console.log('\nSample Listing:');
      console.log(`Title: ${sample.title}`);
      console.log(`Status: ${sample.status}`);
      console.log(`isApproved: ${sample.isApproved}`);
      console.log(`Category: ${sample.category.name}`);
    }

  } catch (e) {
    console.error(e);
  } finally {
    await prisma.$disconnect();
  }
}

main();
