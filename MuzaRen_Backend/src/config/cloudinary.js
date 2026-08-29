const multer = require('multer');
const path = require('path');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('cloudinary').v2;

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_FILE_SIZE = 8 * 1024 * 1024; // 8MB
const MAX_FILES_LISTING = 5;
const MAX_FILES_SINGLE = 1;

function fileFilter(req, file, cb) {
  // Check MIME type
  if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
    return cb(new Error('Invalid file type. Only JPEG, PNG and WebP allowed.'), false);
  }

  // Check file extension matches mime type (rudimentary check)
  const ext = path.extname(file.originalname).toLowerCase();
  const validExts = ['.jpg', '.jpeg', '.png', '.webp'];
  if (!validExts.includes(ext)) {
    return cb(new Error('Invalid file extension.'), false);
  }

  cb(null, true);
}

// ── STORAGE CONFIGURATIONS ────────────────────────────────

// 1. General public uploads (Listings & Avatars)
const publicStorage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'renthubindia_uploads',
    allowed_formats: ['jpg', 'png', 'jpeg', 'webp'],
  },
});

// 2. Private uploads (Verification Documents / IDs)
const privateStorage = new CloudinaryStorage({
  cloudinary: cloudinary,
  params: {
    folder: 'renthubindia/verification-docs',
    allowed_formats: ['jpg', 'png', 'jpeg', 'webp'],
    // Important: Cloudinary type 'upload' allows public access by default. 
    // Setting access_mode 'authenticated' ensures it cannot be viewed via public URL.
    access_mode: 'authenticated',
    type: 'upload', 
  },
});

// ── MULTER INSTANCES ──────────────────────────────────────

// Listing images (max 5 files, 10MB each)
const listingImagesUpload = multer({
  storage: publicStorage,
  fileFilter,
  limits: { fileSize: MAX_FILE_SIZE, files: MAX_FILES_LISTING },
}).array('images', MAX_FILES_LISTING);

// Single public image (avatars, max 5MB)
const avatarUpload = multer({
  storage: publicStorage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024, files: MAX_FILES_SINGLE },
}).single('avatar');

// Verification document (private, max 10MB)
const documentUpload = multer({
  storage: privateStorage,
  fileFilter,
  limits: { fileSize: MAX_FILE_SIZE, files: MAX_FILES_SINGLE },
}).single('document');

// Generic single upload (e.g. for chat images)
const singleImageUpload = multer({
  storage: publicStorage,
  fileFilter,
  limits: { fileSize: MAX_FILE_SIZE, files: MAX_FILES_SINGLE },
}).single('image');

// ── ERROR HANDLER WRAPPER ─────────────────────────────────
function handleUpload(multerMiddleware) {
  return (req, res, next) => {
    multerMiddleware(req, res, (err) => {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          return res.status(400).json({ success: false, message: 'File too large. Maximum size exceeded.' });
        }
        if (err.code === 'LIMIT_FILE_COUNT') {
          return res.status(400).json({ success: false, message: 'Too many files uploaded.' });
        }
        return res.status(400).json({ success: false, message: `Upload error: ${err.message}` });
      }
      if (err) {
        return res.status(400).json({ success: false, message: err.message });
      }
      next();
    });
  };
}

module.exports = {
  cloudinary,
  listingImagesUpload: handleUpload(listingImagesUpload),
  avatarUpload: handleUpload(avatarUpload),
  documentUpload: handleUpload(documentUpload),
  singleImageUpload: handleUpload(singleImageUpload)
};
