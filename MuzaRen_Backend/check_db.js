const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const total = await prisma.listing.count();
  const byStatus = await prisma.listing.groupBy({
    by: ['status', 'isApproved'],
    _count: {
      id: true
    }
  });

  const allListings = await prisma.listing.findMany({
    take: 5,
    select: {
      id: true,
      title: true,
      status: true,
      isApproved: true
    }
  });

  console.log('Total Listings:', total);
  console.log('Stats:', JSON.stringify(byStatus, null, 2));
  console.log('Sample Listings:', JSON.stringify(allListings, null, 2));
}

main()
  .catch(e => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
