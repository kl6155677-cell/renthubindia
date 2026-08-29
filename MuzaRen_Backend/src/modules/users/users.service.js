const bcrypt = require('bcryptjs');
const prisma = require('../../config/db');

const getProfile = async (userId) => {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      avatarUrl: true,
      role: true,
      verificationStatus: true,
      country: true,
      city: true,
      currency: true,
      rating: true,
      createdAt: true,
    }
  });

  if (!user) throw new Error('User not found');
  return user;
};

const updateProfile = async (userId, data) => {
  // Security Hardening: Only allow specific fields to be updated by the user
  const allowedFields = ['name', 'phone', 'city', 'country', 'currency', 'avatarUrl'];
  const filteredData = Object.keys(data)
    .filter(key => allowedFields.includes(key))
    .reduce((obj, key) => {
      obj[key] = data[key];
      return obj;
    }, {});

  if (Object.keys(filteredData).length === 0) {
    throw new Error('No valid fields provided for update');
  }

  const user = await prisma.user.update({
    where: { id: userId },
    data: filteredData,
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      avatarUrl: true,
      role: true,
      verificationStatus: true,
      country: true,
      city: true,
      currency: true,
      rating: true,
      createdAt: true,
      updatedAt: true
    }
  });

  return user;
};

const changePassword = async (userId, oldPassword, newPassword) => {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw new Error('User not found');
  if (!user.passwordHash) throw new Error('OAuth accounts cannot change passwords locally');

  const isMatch = await bcrypt.compare(oldPassword, user.passwordHash);
  if (!isMatch) throw new Error('Incorrect current password');

  const salt = await bcrypt.genSalt(12);
  const passwordHash = await bcrypt.hash(newPassword, salt);

  await prisma.user.update({
    where: { id: userId },
    data: { passwordHash }
  });

  // Security: Invalidate all refresh tokens for this user
  const redis = require('../../config/redis');
  const SecurityLogger = require('../../utils/securityLogger');
  const keys = await redis.keys(`refresh:${userId}:*`);
  if (keys.length > 0) await redis.del(...keys);
  SecurityLogger.tokenRevoked(userId, 'password_change');

  return { message: 'Password changed successfully' };
};

const uploadAvatar = async (userId, avatarUrl) => {
  const user = await prisma.user.update({
    where: { id: userId },
    data: { avatarUrl },
    select: {
      id: true,
      name: true,
      email: true,
      phone: true,
      avatarUrl: true,
      role: true,
      verificationStatus: true,
      country: true,
      city: true,
      currency: true,
      rating: true,
      createdAt: true,
      updatedAt: true
    }
  });
  return user;
};

const updateFCMToken = async (userId, fcmToken) => {
  if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim() === '') {
    throw new Error('Invalid FCM token');
  }

  const token = fcmToken.trim();

  // If another user has this same token, clear it from them first
  // (happens when same device logs into different accounts)
  await prisma.user.updateMany({
    where: {
      fcmToken: token,
      id: { not: userId },
    },
    data: { fcmToken: null },
  });

  // Save token to current user
  await prisma.user.update({
    where: { id: userId },
    data: { fcmToken: token },
  });

  return { message: 'FCM Token updated successfully' };
};

const { paginate } = require('../../utils/paginate');

const getAllUsers = async ({ role, verificationStatus, isBlocked, search, page, limit }) => {
  const where = {};
  if (role && role !== 'ALL')               where.role               = role;
  if (verificationStatus && verificationStatus !== 'ALL') where.verificationStatus = verificationStatus;
  if (isBlocked !== undefined) where.isBlocked = isBlocked === 'true';
  if (search) {
    where.OR = [
      { name:  { contains: search, mode: 'insensitive' } },
      { email: { contains: search, mode: 'insensitive' } },
    ];
  }

  return paginate({
    modelName: 'user',
    where,
    select: {
      id:                 true,
      name:               true,
      email:              true,
      phone:              true,
      avatarUrl:          true,
      role:               true,
      verificationStatus: true,
      isBlocked:          true,
      country:            true,
      city:               true,
      rating:             true,
      createdAt:          true,
    },
    page,
    limit,
  });
};

const blockUser = async (adminId, targetUserId) => {
  if (adminId === targetUserId) throw new Error('Cannot block yourself');

  const user = await prisma.user.findUnique({ where: { id: targetUserId } });
  if (!user) throw new Error('User not found');

  const newBlockStatus = !user.isBlocked;

  await prisma.user.update({
    where: { id: targetUserId },
    data: { isBlocked: newBlockStatus }
  });

  return { message: `User has been successfully ${newBlockStatus ? 'blocked' : 'unblocked'}` };
};

const submitVerification = async (userId, docUrl) => {
  const user = await prisma.user.update({
    where: { id: userId },
    data: {
      verificationDoc: docUrl,
      verificationStatus: 'PENDING'
    }
  });
  return user;
};

const getPublicProfile = async (targetUserId) => {
  const user = await prisma.user.findUnique({
    where: { id: targetUserId },
    select: {
      id: true,
      name: true,
      avatarUrl: true,
      rating: true,
      country: true,
      city: true,
      verificationStatus: true,
      createdAt: true
    }
  });

  if (!user) throw new Error('User not found');
  return user;
};

module.exports = {
  getProfile,
  updateProfile,
  uploadAvatar,
  updateFCMToken,
  getAllUsers,
  blockUser,
  submitVerification,
  getPublicProfile,
  changePassword
};
