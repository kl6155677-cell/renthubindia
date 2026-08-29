const prisma = require('../config/db');

/**
 * Generate a 6-digit OTP, store it in the database and return the code
 */
const generateOTP = async (userId) => {
  // Generate random 6-digit number
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  
  // Set expiration to 10 minutes from now
  const expiresAt = new Date();
  expiresAt.setMinutes(expiresAt.getMinutes() + 10);

  // Invalidate any existing unused OTPs for this user
  await prisma.oTP.updateMany({
    where: {
      userId,
      used: false,
    },
    data: {
      used: true,
    },
  });

  // Create new OTP
  const newOtp = await prisma.oTP.create({
    data: {
      userId,
      code,
      expiresAt,
    },
  });

  return newOtp.code;
};

/**
 * Verify if the provided OTP is valid, unused, and not expired
 */
const verifyOTP = async (userId, code, markUsed = true) => {
  const otpRecord = await prisma.oTP.findFirst({
    where: {
      userId,
      code,
      used: false,
      expiresAt: {
        gt: new Date(), // Must be greater than current time
      },
    },
  });

  if (!otpRecord) return false;

  // Mark as used if requested
  if (markUsed) {
    await prisma.oTP.update({
      where: { id: otpRecord.id },
      data: { used: true },
    });
  }

  return true;
};

module.exports = {
  generateOTP,
  verifyOTP,
};
