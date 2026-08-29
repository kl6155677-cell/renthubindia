const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const prisma = require('./src/config/db');
const { cloudinary } = require('./src/config/cloudinary');

async function migrate() {
  console.log('🖼️ Starting Cloudinary Image Migration...');

  // 1. Find all images that are still using Unsplash
  const images = await prisma.listingImage.findMany({
    where: {
      imageUrl: {
        contains: 'unsplash.com'
      }
    }
  });

  if (images.length === 0) {
    console.log('✅ No images found needing migration.');
    return;
  }

  console.log(`🚀 Found ${images.length} images to migrate. This may take a few minutes...`);

  let successCount = 0;
  let failCount = 0;

  for (let i = 0; i < images.length; i++) {
    const img = images[i];
    try {
      console.log(`📤 Uploading image ${i + 1}/${images.length}: ${img.imageUrl.split('?')[0]}...`);
      
      // Upload to Cloudinary directly from URL
      const uploadResult = await cloudinary.uploader.upload(img.imageUrl, {
        folder: 'renthubindia_uploads',
        resource_type: 'image',
        // Optional: you can add transformations here
      });

      // Update the database with the new secure URL
      await prisma.listingImage.update({
        where: { id: img.id },
        data: {
          imageUrl: uploadResult.secure_url        }
      });

      successCount++;
      console.log(`  ✅ Success: ${uploadResult.secure_url}`);
    } catch (error) {
      failCount++;
      console.error(`  ❌ Failed to migrate image ${img.id}:`, error.message);
    }
  }

  console.log('\n--- Migration Summary ---');
  console.log(`✨ Successfully migrated: ${successCount}`);
  console.log(`⚠️ Failed: ${failCount}`);
  console.log('--------------------------');
}

migrate()
  .catch((e) => {
    console.error('❌ Critical Error during migration:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
