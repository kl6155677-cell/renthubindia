const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function debugChats() {
  try {
    const chats = await prisma.chat.findMany({
      include: {
        listing: { select: { title: true } },
        renter: { select: { name: true, id: true } },
        owner: { select: { name: true, id: true } }
      }
    });

    console.log('--- ALL CHATS ---');
    chats.forEach(c => {
      console.log(`ID: ${c.id}`);
      console.log(`Listing: ${c.listing.title} (${c.listingId})`);
      console.log(`Renter: ${c.renter.name} (${c.renterId})`);
      console.log(`Owner: ${c.owner.name} (${c.ownerId})`);
      console.log('-----------------');
    });
  } catch (err) {
    console.error(err);
  } finally {
    await prisma.$disconnect();
  }
}

debugChats();
