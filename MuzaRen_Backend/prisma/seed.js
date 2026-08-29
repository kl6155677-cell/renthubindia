require('dotenv').config();
const prisma = require('../src/config/db');
const bcrypt = require('bcryptjs');

async function main() {
  console.log('Seeding root application defaults...');

  // 1. Seed the default master administrator
  // Generating hash outside of auth service organically for exact deployment script
  const salt = await bcrypt.genSalt(12);
  const hashedPassword = await bcrypt.hash('Admin@1234', salt);

  const admin = await prisma.user.upsert({
    where: { email: 'admin@renthubindia.com' },
    update: {},
    create: {
      email: 'admin@renthubindia.com',
      passwordHash: hashedPassword,
      name: 'Super Admin',
      role: 'ADMIN',
      verificationStatus: 'VERIFIED',
      phone: '+10000000000'
    }
  });

  console.log('✅ Admin initialized successfully.');

  // 2. Seed default platform categories
  const categoriesToSeed = [
    { name: 'Electronics', slug: 'electronics', icon: '💻' },
    { name: 'Vehicles', slug: 'vehicles', icon: '🚗' },
    { name: 'Furniture', slug: 'furniture', icon: '🛋️' },
    { name: 'Lighting', slug: 'lighting', icon: '💡' },
    { name: 'Textiles', slug: 'textiles', icon: '🪟' },
    { name: 'Outdoor', slug: 'outdoor', icon: '🏖️' },
    { name: 'Kitchen', slug: 'kitchen', icon: '☕' },
    { name: 'Art', slug: 'art', icon: '🎨' },
    { name: 'Storage', slug: 'storage', icon: '📦' },
    { name: 'Bedroom', slug: 'bedroom', icon: '🛏️' },
    { name: 'Wellness', slug: 'wellness', icon: '🌿' },
    { name: 'Workspace', slug: 'workspace', icon: '💼' },
    { name: 'Kids', slug: 'kids', icon: '👶' },
    { name: 'Smart Home', slug: 'smart-home', icon: '📱' },
    { name: 'Sports & Outdoors', slug: 'sports-outdoors', icon: '⚽' },
    { name: 'Apparel & Fashion', slug: 'apparel', icon: '👗' },
    { name: 'Tools & Hardware', slug: 'tools', icon: '🔨' }
  ];

  console.log('Seeding marketplace categories...');

  for (const cat of categoriesToSeed) {
    await prisma.category.upsert({
      where: { slug: cat.slug },
      update: {},
      create: {
        name: cat.name,
        slug: cat.slug,
        icon: cat.icon
      }
    });
  }

  console.log('✅ Categories embedded successfully.');

  // 3. Seed sample data for development
  console.log('Generating sample marketplace data...');
  
  const testUser = await prisma.user.upsert({
    where: { email: 'test@renthubindia.com' },
    update: {},
    create: {
      email: 'test@renthubindia.com',
      name: 'John Doe',
      phone: '+1234567890',
      verificationStatus: 'VERIFIED',
      country: 'india',
      city: 'mumbai'
    }
  });

  const categoryElectronics = await prisma.category.findUnique({ where: { slug: 'electronics' } });
  const categoryVehicles = await prisma.category.findUnique({ where: { slug: 'vehicles' } });
  const categoryFurniture = await prisma.category.findUnique({ where: { slug: 'furniture' } });

  const sampleListings = [
    {
      title: 'Professional DSLR Camera',
      description: 'High-end DSLR camera perfect for professional photography and cinematic videos.',
      pricePerDay: 45.00,
      location: 'Andheri West, Mumbai',
      categoryId: categoryElectronics.id,
      userId: testUser.id,
      status: 'ACTIVE',
      isApproved: true
    },
    {
      title: 'Gaming Laptop (RTX 4080)',
      description: 'Powerful gaming laptop capable of running any modern game at ultra settings.',
      pricePerDay: 65.50,
      location: 'Bandra, Mumbai',
      categoryId: categoryElectronics.id,
      userId: testUser.id,
      status: 'ACTIVE',
      isApproved: true
    },
    {
      title: 'Tesla Model 3 Rental',
      description: 'Experience the future of driving with a fully electric Tesla Model 3.',
      pricePerDay: 120.00,
      location: 'Worli, Mumbai',
      categoryId: categoryVehicles.id,
      userId: testUser.id,
      status: 'ACTIVE',
      isApproved: true
    },
    {
      title: 'Mountain Bike (21 Speed)',
      description: 'Robust mountain bike perfect for off-road trails and city commuting.',
      pricePerDay: 15.00,
      location: 'Powai, Mumbai',
      categoryId: categoryVehicles.id,
      userId: testUser.id,
      status: 'ACTIVE',
      isApproved: true
    },
    {
      title: 'Modern Leather Sofa',
      description: 'Extremely comfortable 3-seater leather sofa, perfect for events or temporary staging.',
      pricePerDay: 30.00,
      location: 'Juhu, Mumbai',
      categoryId: categoryFurniture.id,
      userId: testUser.id,
      status: 'ACTIVE',
      isApproved: true
    },
    {
      title: 'Wooden Dining Table',
      description: 'Elegant 6-seater wooden dining table for dinner parties and family gatherings.',
      pricePerDay: 25.00,
      location: 'Colaba, Mumbai',
      categoryId: categoryFurniture.id,
      userId: testUser.id,
      status: 'ACTIVE',
      isApproved: true
    }
  ];

  for (const list of sampleListings) {
    await prisma.listing.upsert({
      where: { id: `seed-listing-${list.title.toLowerCase().replace(/ /g, '-')}` }, // deterministic ID for upsert
      update: {},
      create: {
        id: `seed-listing-${list.title.toLowerCase().replace(/ /g, '-')}`,
        ...list
      }
    });
  }

  console.log('✅ Sample listings created successfully.');
  console.log('Database Seeding is 100% complete.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
