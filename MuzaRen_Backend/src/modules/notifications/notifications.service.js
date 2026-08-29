const prisma = require('../../config/db');

const { paginate } = require('../../utils/paginate');

const getUserNotifications = async (userId, { page, limit }) => {
  const [result, unreadCount] = await Promise.all([
    paginate({
      modelName: 'notification',
      where:     { userId },
      orderBy:   { createdAt: 'desc' },
      page,
      limit,
    }),
    prisma.notification.count({ where: { userId, isRead: false } }),
  ]);

  return {
    ...result,
    unreadCount,
  };
};

const markAsRead = async (userId, notificationId) => {
  const notification = await prisma.notification.findUnique({
    where: { id: notificationId }
  });

  if (!notification) throw new Error('Notification not found');
  if (notification.userId !== userId) throw new Error('Unauthorized');

  await prisma.notification.update({
    where: { id: notificationId },
    data: { isRead: true }
  });

  const unreadCount = await prisma.notification.count({
    where: { userId, isRead: false }
  });

  return { unreadCount };
};

const markAllAsRead = async (userId) => {
  await prisma.notification.updateMany({
    where: { userId, isRead: false },
    data: { isRead: true }
  });

  return { unreadCount: 0 };
};

module.exports = {
  getUserNotifications,
  markAsRead,
  markAllAsRead
};
