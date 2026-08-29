require('dotenv').config();
const prisma = require('./src/config/db');

async function main() {
  console.log('Clearing all listings and dependent records from the database...');
  
  try {
    const messages = await prisma.message.deleteMany();
    console.log(`Deleted ${messages.count} messages.`);

    const chats = await prisma.chat.deleteMany();
    console.log(`Deleted ${chats.count} chats.`);

    const reviews = await prisma.review.deleteMany();
    console.log(`Deleted ${reviews.count} reviews.`);

    const bookings = await prisma.booking.deleteMany();
    console.log(`Deleted ${bookings.count} bookings.`);

    const images = await prisma.listingImage.deleteMany();
    console.log(`Deleted ${images.count} listing images.`);

    const reports = await prisma.report.deleteMany({
      where: { targetListingId: { not: null } }
    });
    console.log(`Deleted ${reports.count} reports aimed at listings.`);

    const listings = await prisma.listing.deleteMany();
    console.log(`Successfully deleted ${listings.count} listings.`);
    
    console.log('Database listings cleared successfully!');
  } catch (err) {
    console.error('Error clearing database:', err);
  } finally {
    process.exit(0);
  }
}

main();
