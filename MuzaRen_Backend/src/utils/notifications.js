const admin = require('firebase-admin');
const prisma = require('../config/db');

/**
 * Send a notification to a user.
 * Always saves to PostgreSQL first, then emits Socket.IO event for live badge update,
 * then sends FCM if token exists.
 *
 * @param {object} io - Socket.IO server instance (from getIO())
 * @param {object} params
 * @param {string} params.userId - recipient user ID
 * @param {string} params.title - notification title
 * @param {string} params.body - notification body text
 * @param {string} params.type - type: booking_update | new_message | verification | system
 * @param {object} params.data - extra data for deep linking { chatId, listingId, bookingId }
 */
async function sendNotification(io, { userId, title, body, type, data = {}, fcmToken }) {
  try {
    // ── STEP 1: Save notification to PostgreSQL ──────────────
    const notification = await prisma.notification.create({
      data: { userId, title, body, type, isRead: false, data },
    });

    // ── STEP 2: Get unread count for badge ───────────────────
    const unreadCount = await prisma.notification.count({
      where: { userId, isRead: false },
    });

    // ── STEP 3: Emit Socket.IO event ─────────────────────────
    if (io) {
      io.to(`user_${userId}`).emit('notification_received', {
        notification: {
          id: notification.id,
          title,
          body,
          type,
          data,
          isRead: false,
          createdAt: notification.createdAt,
        },
        unreadCount,
      });
    }

    // ── STEP 4: Send FCM push ────────────────────────────────
    // Use provided fcmToken or fetch it if not provided
    let targetToken = fcmToken;
    if (!targetToken) {
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { fcmToken: true },
      });
      targetToken = user?.fcmToken;
    }

    if (targetToken) {
      // Don't await sendFCM to avoid blocking the main notification flow further
      sendFCM(targetToken, { title, body, type, data, userId });
    }

    return notification;
  } catch (error) {
    console.error(`❌ Failed to send notification to user ${userId}:`, error);
    // Never throw — notification failure should never crash the main flow
  }
}

/**
 * Send raw FCM push notification to a device token.
 * Handles invalid token errors by clearing the token from DB.
 */
async function sendFCM(fcmToken, { title, body, type, data, userId }) {
  try {
    const message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: {
        // All data values must be strings for FCM
        type: String(type || 'system'),
        chatId: String(data.chatId || ''),
        listingId: String(data.listingId || ''),
        bookingId: String(data.bookingId || ''),
        userId: String(userId || ''),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'renthubindia_channel',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            badge: 1,
            sound: 'default',
            contentAvailable: true,
          },
        },
        headers: {
          'apns-priority': '10',
        },
      },
    };

    await admin.messaging().send(message);
    console.log(`✅ FCM sent to user ${userId}`);
  } catch (error) {
    // Handle invalid/expired FCM token
    if (
      error.code === 'messaging/invalid-registration-token' ||
      error.code === 'messaging/registration-token-not-registered'
    ) {
      console.warn(`⚠️ Invalid FCM token for user ${userId} — clearing token`);
      // Clear the invalid token from the database
      if (userId) {
        await prisma.user.update({
          where: { id: userId },
          data: { fcmToken: null },
        });
      }
    } else {
      console.error('❌ FCM send error:', error);
    }
  }
}

/**
 * Send notification to multiple users at once.
 * Used for admin broadcasts.
 */
async function sendBulkNotification(io, userIds, { title, body, type, data }) {
  const promises = userIds.map((userId) =>
    sendNotification(io, { userId, title, body, type, data })
  );
  await Promise.allSettled(promises);
}

module.exports = { sendNotification, sendFCM, sendBulkNotification };
