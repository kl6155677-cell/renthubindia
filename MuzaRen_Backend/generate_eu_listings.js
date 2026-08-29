const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const prisma = require('./src/config/db');

async function seedEU() {
  console.log('🇪🇺 Starting generation of Netherlands & Germany listings...');

  const testUser = await prisma.user.findFirst({ where: { email: 'test@renthubindia.com' } });
  const categories = await prisma.category.findMany();
  const catMap = {};
  categories.forEach(c => catMap[c.slug] = c.id);

  const euItems = [
    // Netherlands
    { title: 'Babboe Electric Cargo Bike', price: 25, cat: 'vehicles', city: 'Amsterdam', country: 'Netherlands', img: 'https://images.unsplash.com/photo-1485965120184-e220f721d03e' },
    { title: 'Amsterdam Canal Boat (6 Pax)', price: 150, cat: 'vehicles', city: 'Amsterdam', country: 'Netherlands', img: 'https://images.unsplash.com/photo-1516467008713-3932e6ee5361' },
    { title: 'Pioneer DJ Setup (Nexus 2)', price: 85, cat: 'electronics', city: 'Rotterdam', country: 'Netherlands', img: 'https://images.unsplash.com/photo-1571266028243-e4bb3339439a' },
    { title: 'Philips Hue Smart Home Kit', price: 10, cat: 'electronics', city: 'Eindhoven', country: 'Netherlands', img: 'https://images.unsplash.com/photo-1558002038-1055907df827' },
    { title: 'VanMoof S3 Electric Bike', price: 30, cat: 'vehicles', city: 'Utrecht', country: 'Netherlands', img: 'https://images.unsplash.com/photo-1485965120184-e220f721d03e' },

    // Germany
    { title: 'Audi RS6 Avant (Daily Rental)', price: 280, cat: 'vehicles', city: 'Munich', country: 'Germany', img: 'https://images.unsplash.com/photo-1541348263662-e0c8de4259ba' },
    { title: 'Authentic Bavarian Lederhosen', price: 45, cat: 'apparel', city: 'Munich', country: 'Germany', img: 'https://images.unsplash.com/photo-1594932224828-b4b059b6fe1c' },
    { title: 'Bosch Professional Impact Drill', price: 18, cat: 'tools', city: 'Berlin', country: 'Germany', img: 'https://images.unsplash.com/photo-1504148455328-c376907d081c' },
    { title: 'Porsche 911 Carrera S', price: 350, cat: 'vehicles', city: 'Stuttgart', country: 'Germany', img: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70' },
    { title: 'Bernina Sewing Machine', price: 20, cat: 'electronics', city: 'Berlin', country: 'Germany', img: 'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c' }
  ];

  for (let i = 0; i < euItems.length; i++) {
    const item = euItems[i];
    const categoryId = catMap[item.cat] || categories[0].id;

    await prisma.listing.create({
      data: {
        id: `eu-listing-${i}-${Date.now()}`,
        userId: testUser.id,
        categoryId: categoryId,
        title: item.title,
        description: `Premium ${item.title} available for rent in ${item.city}, ${item.country}. High quality and reliable.`,
        pricePerDay: item.price,
        location: item.city,
        city: item.city,
        country: item.country,
        status: 'ACTIVE',
        isApproved: true,
        availableFrom: new Date(),
        availableTo: new Date(Date.now() + 1000 * 60 * 60 * 24 * 365),
        images: {
          create: [{ imageUrl: `${item.img}?auto=format&fit=crop&q=80&w=1000`, sortOrder: 0 }]
        }
      }
    });
    console.log(`✅ Created: ${item.title} in ${item.country}`);
  }

  console.log('🎉 EU Seed Complete!');
}

seedEU().finally(() => prisma.$disconnect());
