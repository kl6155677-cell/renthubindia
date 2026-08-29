const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const prisma = require('./src/config/db');

async function main() {
  console.log('🚀 Starting generation of 50 fake listings...');

  // 1. Get test user and categories
  const testUser = await prisma.user.findFirst({ where: { email: 'test@renthubindia.com' } });
  if (!testUser) {
    console.error('❌ Error: test@renthubindia.com not found. Please run "node prisma/seed.js" first.');
    return;
  }

  const categories = await prisma.category.findMany();
  const catMap = {};
  categories.forEach(c => catMap[c.slug] = c.id);

  console.log(`📌 Found ${categories.length} categories. Assigning listings...`);

  const mockLocations = [
    { city: 'Singapore', country: 'Singapore' },
    { city: 'Santa Clara', country: 'United States' },
    { city: 'New York City', country: 'United States' },
    { city: 'Dubai', country: 'United Arab Emirates' },
    { city: 'London', country: 'United Kingdom' },
    { city: 'Paris', country: 'France' },
    { city: 'Casablanca', country: 'Morocco' },
    { city: 'Istanbul', country: 'Turkey' },
    { city: 'Riyadh', country: 'Saudi Arabia' },
    { city: 'Doha', country: 'Qatar' }
  ];

  const items = [
    // Electronics
    { title: 'Sony A7IV Mirrorless Camera', price: 85, cat: 'electronics', img: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32' },
    { title: 'DJI Mavic 3 Pro Drone', price: 95, cat: 'electronics', img: 'https://images.unsplash.com/photo-1508614589041-895b88991e3e' },
    { title: 'Bose QuietComfort 45', price: 25, cat: 'electronics', img: 'https://images.unsplash.com/photo-1546435770-a3e426bf472b' },
    { title: 'PS5 Console + 2 Controllers', price: 40, cat: 'electronics', img: 'https://images.unsplash.com/photo-1606813907291-d86ebb9c74ad' },
    { title: 'MacBook Pro M2 Max', price: 120, cat: 'electronics', img: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8' },
    { title: 'Samsung 65" QLED TV', price: 55, cat: 'electronics', img: 'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1' },
    { title: 'iPad Pro 12.9 + Apple Pencil', price: 45, cat: 'electronics', img: 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0' },
    { title: 'Nintendo Switch OLED', price: 20, cat: 'electronics', img: 'https://images.unsplash.com/photo-1585671962215-473adff899a7' },
    
    // Vehicles
    { title: 'Tesla Model S Plaid', price: 250, cat: 'vehicles', img: 'https://images.unsplash.com/photo-1617788138017-80ad40651399' },
    { title: 'BMW M4 Competition', price: 180, cat: 'vehicles', img: 'https://images.unsplash.com/photo-1555215695-3004980ad54e' },
    { title: 'Ducati Panigale V4', price: 110, cat: 'vehicles', img: 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc' },
    { title: 'Segway Ninebot Max G30', price: 15, cat: 'vehicles', img: 'https://images.unsplash.com/photo-1605333396915-47ed6b68a00e' },
    { title: 'Specialized Mountain Bike', price: 35, cat: 'vehicles', img: 'https://images.unsplash.com/photo-1532298229144-0ec0c57515c7' },
    { title: 'Jeep Wrangler Rubicon', price: 95, cat: 'vehicles', img: 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf' },
    { title: 'Harley Davidson Fat Bob', price: 75, cat: 'vehicles', img: 'https://images.unsplash.com/photo-1558981403-c5f9899a28bc' },
    { title: 'Yacht Charter (4 Hours)', price: 800, cat: 'vehicles', img: 'https://images.unsplash.com/photo-1567899378494-47b22a2ae96a' },

    // Furniture
    { title: 'Herman Miller Aeron Chair', price: 25, cat: 'furniture', img: 'https://images.unsplash.com/photo-1505797149-43b00fe90004' },
    { title: 'Mid-Century Modern Sofa', price: 45, cat: 'furniture', img: 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc' },
    { title: 'Electric Standing Desk', price: 20, cat: 'furniture', img: 'https://images.unsplash.com/photo-1592078615290-033ee584e267' },
    { title: 'Marble Dining Table (6 Seater)', price: 60, cat: 'furniture', img: 'https://images.unsplash.com/photo-1530018607912-eff2df114f11' },
    { title: 'SMEG Retro Fridge', price: 35, cat: 'furniture', img: 'https://images.unsplash.com/photo-1571175432230-01c248a51a9a' },
    { title: 'Kingsize Velvet Bed Frame', price: 40, cat: 'furniture', img: 'https://images.unsplash.com/photo-1505691938895-1758d7eaa511' },
    
    // Sports & Outdoors
    { title: 'North Face 4-Person Tent', price: 25, cat: 'sports-outdoors', img: 'https://images.unsplash.com/photo-1478131143081-80f7f84ca84c' },
    { title: 'Inflatable Paddle Board', price: 35, cat: 'sports-outdoors', img: 'https://images.unsplash.com/photo-1500336624523-d727130c3328' },
    { title: 'Set of Golf Clubs (TaylorMade)', price: 50, cat: 'sports-outdoors', img: 'https://images.unsplash.com/photo-1535131749006-b7f58c99034b' },
    { title: 'Portable Propane BBQ Grill', price: 15, cat: 'sports-outdoors', img: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a' },
    { title: 'Foldable Kayak (Single)', price: 40, cat: 'sports-outdoors', img: 'https://images.unsplash.com/photo-1527230249020-c01f8a8d2644' },
    
    // Apparel & Fashion
    { title: 'Designer Tuxedo (Rent)', price: 95, cat: 'apparel', img: 'https://images.unsplash.com/photo-1594932224828-b4b059b6fe1c' },
    { title: 'Luxury Silk Saree', price: 55, cat: 'apparel', img: 'https://images.unsplash.com/photo-1583391733956-3750e0ff4e8b' },
    { title: 'Vintage Leather Jacket', price: 25, cat: 'apparel', img: 'https://images.unsplash.com/photo-1551028719-00167b16eac5' },
    { title: 'Designer Evening Gown', price: 120, cat: 'apparel', img: 'https://images.unsplash.com/photo-1566174053879-31528523f8ae' },
    
    // Mix and match to reach 50
    { title: 'Robot Vacuum Cleaner', price: 15, cat: 'electronics', img: 'https://images.unsplash.com/photo-1518640467707-6811f4a6ab73' },
    { title: 'Projector + 100" Screen', price: 45, cat: 'electronics', img: 'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c' },
    { title: 'Electric Guitar + Amp', price: 30, cat: 'electronics', img: 'https://images.unsplash.com/photo-1550291652-6ea9114a47b1' },
    { title: 'Dyson Airwrap Styler', price: 25, cat: 'electronics', img: 'https://images.unsplash.com/photo-1620331311520-246422ff83f9' },
    { title: 'Air Purifier (HEPA)', price: 10, cat: 'electronics', img: 'https://images.unsplash.com/photo-1622467820359-9943343336d3' },
    { title: 'Professional Poker Set', price: 10, cat: 'furniture', img: 'https://images.unsplash.com/photo-1613461920867-9ea115f17079' },
    { title: 'Bean Bag Chair (XL)', price: 8, cat: 'furniture', img: 'https://images.unsplash.com/photo-1592078615290-033ee584e267' },
    { title: 'Handheld Steam Cleaner', price: 12, cat: 'tools', img: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a' },
    { title: 'Power Drill (Cordless)', price: 15, cat: 'tools', img: 'https://images.unsplash.com/photo-1504148455328-c376907d081c' },
    { title: 'Pressure Washer (2000 PSI)', price: 25, cat: 'tools', img: 'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50' },
    { title: 'Electric Lawn Mower', price: 30, cat: 'tools', img: 'https://images.unsplash.com/photo-1589149053231-4777a944a10b' },
    { title: 'Telescopic Ladder', price: 12, cat: 'tools', img: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a' },
    { title: 'Portable Air Conditioner', price: 40, cat: 'electronics', img: 'https://images.unsplash.com/photo-1622467820359-9943343336d3' },
    { title: 'Camping Stove + Cookware', price: 10, cat: 'sports-outdoors', img: 'https://images.unsplash.com/photo-1523987355523-c7b5b0dd90a7' },
    { title: 'Hammock with Stand', price: 12, cat: 'sports-outdoors', img: 'https://images.unsplash.com/photo-1473448912268-2022ce9509d8' },
    { title: 'Dumbbell Set (20kg)', price: 15, cat: 'sports-outdoors', img: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438' },
    { title: 'Massage Chair', price: 80, cat: 'furniture', img: 'https://images.unsplash.com/photo-1592078615290-033ee584e267' },
    { title: 'Pool Table (Foldable)', price: 50, cat: 'furniture', img: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018' },
    { title: 'Electric Piano (88 Keys)', price: 40, cat: 'electronics', img: 'https://images.unsplash.com/photo-1520529712542-82c83a05b3d0' }
  ];

  console.log(`✨ Preparing to insert ${items.length} listings...`);

  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const loc = mockLocations[i % mockLocations.length];
    
    const categoryId = catMap[item.cat];
    if (!categoryId) {
      console.warn(`⚠️ Warning: Category ${item.cat} not found. Skipping ${item.title}.`);
      continue;
    }

    const listingId = `fake-listing-${i}-${Date.now()}`;
    
    await prisma.listing.create({
      data: {
        id: listingId,
        userId: testUser.id,
        categoryId: categoryId,
        title: item.title,
        description: `${item.title} available for short-term rent. High quality and well maintained. Perfect for your next project or event. Located in ${loc.city}.`,
        pricePerDay: item.price,
        location: loc.city,
        city: loc.city,
        country: loc.country,
        status: 'ACTIVE',
        isApproved: true,
        availableFrom: new Date(),
        availableTo: new Date(Date.now() + 1000 * 60 * 60 * 24 * 365), // 1 year
        images: {
          create: [
            {
              imageUrl: `${item.img}?auto=format&fit=crop&q=80&w=1000`,
              sortOrder: 0
            }
          ]
        }
      }
    });

    if ((i + 1) % 10 === 0) console.log(`✅ Progress: ${i + 1}/${items.length} created.`);
  }

  console.log('🎉 Successfully created 50 listings!');
}

main()
  .catch((e) => {
    console.error('❌ Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
