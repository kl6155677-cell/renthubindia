const { Server } = require('socket.io');
const { verifyAccessToken } = require('../utils/jwt');
const prisma = require('./db');
const redis = require('./redis');
const { sendNotification } = require('../utils/notifications');
const crypto = require('crypto');

// Map to track online users: { userId → socketId }
// Map to track online users: { userId → socketId }
const onlineUsers = new Map();
let _io = null;

function getIO() {
  if (!_io) {
    throw new Error('Socket.IO not initialized');
  }
  return _io;
}

// Rate limit socket messages using Redis
async function checkMessageRateLimit(userId) {
  const key = `socket:msg_rate:${userId}`;
  const count = await redis.incr(key);
  if (count === 1) await redis.expire(key, 60); // 1 minute window
  return count <= 30; // max 30 messages per minute
}

function initSocket(httpServer) {
  // Parse ALLOWED_ORIGINS from environment, fallback to * for dev
  const allowedOrigins = process.env.ALLOWED_ORIGINS 
    ? process.env.ALLOWED_ORIGINS.split(',') 
    : '*';

  _io = new Server(httpServer, {
    transports: ['websocket'],
    pingTimeout: 60000,
    pingInterval: 25000,
    cors: {
      origin: allowedOrigins,
      methods: ['GET', 'POST']
    }
  });

  // ── AUTH MIDDLEWARE ─────────────────────────────────────────
  _io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token?.replace('Bearer ', '');
      if (!token) return next(new Error('No token provided'));

      // Check blacklist
      const isBlacklisted = await redis.get(`blacklist:${token}`);
      if (isBlacklisted) return next(new Error('Token revoked'));

      const decoded = verifyAccessToken(token);

      // Check user exists and is not blocked
      const user = await prisma.user.findUnique({
        where: { id: decoded.id },
        select: { id: true, role: true, isBlocked: true },
      });
      if (!user || user.isBlocked) return next(new Error('User not authorized or blocked'));

      socket.userId = decoded.id;
      next();
    } catch (err) {
      next(new Error('Authentication failed'));
    }
  });

  _io.on('connection', (socket) => {
    const userId = socket.userId;

    // Track user as online
    onlineUsers.set(userId, socket.id);

    // Join a room unique to this user ID
    socket.join(`user_${userId}`);

    // ─── EVENT: join_chat ───────────────────────────────
    socket.on('join_chat', async ({ chatId }) => {
      try {
        if (!chatId || typeof chatId !== 'string') return;
        const chat = await prisma.chat.findUnique({ where: { id: chatId } });
        if (!chat) return socket.emit('error', { message: 'Chat not found' });
        if (chat.renterId !== userId && chat.ownerId !== userId) {
          return socket.emit('error', { message: 'Unauthorized' });
        }

        socket.join(chatId);

        const messages = await prisma.message.findMany({
          where: { chatId },
          orderBy: { createdAt: 'desc' },
          take: 50,
          include: { sender: { select: { id: true, name: true, avatarUrl: true } } }
        });

        messages.reverse();
        socket.emit('chat_history', { chatId, messages });
      } catch (err) {
        socket.emit('error', { message: 'Failed to join chat' });
      }
    });

    // ─── EVENT: load_more_messages ──────────────────────
    socket.on('load_more_messages', async ({ chatId, skip }) => {
      try {
        if (!chatId || typeof chatId !== 'string' || typeof skip !== 'number') return;
        const chat = await prisma.chat.findUnique({ where: { id: chatId } });
        if (!chat) return socket.emit('error', { message: 'Chat not found' });
        if (chat.renterId !== userId && chat.ownerId !== userId) {
          return socket.emit('error', { message: 'Unauthorized' });
        }

        const messages = await prisma.message.findMany({
          where: { chatId },
          orderBy: { createdAt: 'desc' },
          take: 50,
          skip: skip,
          include: { sender: { select: { id: true, name: true, avatarUrl: true } } }
        });

        messages.reverse();
        socket.emit('more_messages_loaded', { chatId, messages });
      } catch (err) {
        socket.emit('error', { message: 'Failed to load more messages' });
      }
    });

    // ─── EVENT: send_message ────────────────────────────
    socket.on('send_message', async ({ chatId, text, replyToId, tempId }) => {
      try {
        if (!chatId || typeof chatId !== 'string') return;
        
        // Input validation
        if (!text || typeof text !== 'string' || !text.trim()) {
          return socket.emit('error', { message: 'Message text is required' });
        }
        if (text.length > 5000) {
          return socket.emit('error', { message: 'Message too long (max 5000 characters)' });
        }

        // Rate limit check
        const allowed = await checkMessageRateLimit(userId);
        if (!allowed) {
          return socket.emit('error', { message: 'Message rate limit exceeded. Slow down.' });
        }

        // Verify user belongs to this chat BEFORE DB write
        const chat = await prisma.chat.findUnique({
          where: { id: chatId },
          select: { 
            renterId: true, 
            ownerId: true,
            renter: { select: { id: true, name: true, avatarUrl: true, fcmToken: true } },
            owner:  { select: { id: true, name: true, avatarUrl: true, fcmToken: true } }
          }
        });

        if (!chat) return socket.emit('error', { message: 'Chat not found' });
        if (chat.renterId !== userId && chat.ownerId !== userId) {
          return socket.emit('error', { message: 'Unauthorized' });
        }

        const isRenter = chat.renterId === userId;
        const senderInfo = isRenter ? chat.renter : chat.owner;
        const receiverId = isRenter ? chat.ownerId : chat.renterId;
        const receiverInfo = isRenter ? chat.owner : chat.renter;

        const messageId = crypto.randomUUID();
        const now = new Date();

        let replyToData = null;
        if (replyToId && typeof replyToId === 'string') {
          replyToData = await prisma.message.findUnique({
            where: { id: replyToId },
            select: { id: true, text: true, imageUrl: true, sender: { select: { name: true } } }
          });
        }

        const message = {
          id: messageId,
          chatId,
          senderId: userId,
          text: text.trim(),
          read: false,
          replyToId,
          createdAt: now,
          updatedAt: now,
          sender: { id: senderInfo.id, name: senderInfo.name, avatarUrl: senderInfo.avatarUrl },
          replyTo: replyToData
        };

        socket.emit('message_sent', { message, tempId });
        socket.to(chatId).emit('new_message', { message });

        try {
          await prisma.message.create({
            data: { 
              id: messageId,
              chatId, 
              senderId: userId, 
              text: text.trim(), 
              read: false,
              replyToId
            }
          });

          await prisma.chat.update({
            where: { id: chatId },
            data: { updatedAt: now }
          });

          if (!onlineUsers.has(receiverId)) {
            sendNotification(_io, {
              userId: receiverId,
              title: senderInfo.name,
              body: text.trim().length > 50 ? text.trim().substring(0, 50) + '...' : text.trim(),
              type: 'new_message',
              data: { chatId },
              fcmToken: receiverInfo.fcmToken
            }).catch(err => console.error('Error sending notification:', err));
          }
        } catch (dbErr) {
          console.error('Critical Error saving message, rolling back:', dbErr);
          _io.to(chatId).emit('message_deleted', { id: messageId, chatId, deleteType: 'for_everyone' });
          socket.emit('error', { message: 'Message failed to deliver.' });
        }
      } catch (err) {
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // ─── EVENT: mark_read ───────────────────────────────
    socket.on('mark_read', async ({ chatId }) => {
      try {
        if (!chatId || typeof chatId !== 'string') return;
        socket.to(chatId).emit('messages_read', { chatId, readBy: userId });
        prisma.message.updateMany({
          where: { chatId, senderId: { not: userId }, read: false },
          data: { read: true }
        }).catch(err => console.error('Error marking messages as read:', err));
      } catch (err) {
        socket.emit('error', { message: 'Failed to mark as read' });
      }
    });

    // ─── EVENT: typing & stop_typing ────────────────────
    socket.on('typing', ({ chatId }) => {
      if (chatId) socket.to(chatId).emit('user_typing', { userId, chatId });
    });

    socket.on('stop_typing', ({ chatId }) => {
      if (chatId) socket.to(chatId).emit('stop_typing', { userId, chatId });
    });

    socket.on('leave_chat', ({ chatId }) => {
      if (chatId) socket.leave(chatId);
    });

    // ─── EVENT: edit_message ────────────────────────────
    socket.on('edit_message', async ({ messageId, newText }) => {
      try {
        if (!messageId || typeof messageId !== 'string') return;
        const message = await require('../modules/chat/chat.service').editMessage(messageId, userId, newText);

        _io.to(message.chatId).emit('message_edited', {
          messageId: message.id,
          chatId: message.chatId,
          newText: message.text,
          editedAt: message.editedAt
        });
      } catch (err) {
        socket.emit('error', { message: err.message || 'Failed to edit message' });
      }
    });

    // ─── EVENT: delete_message ──────────────────────────
    socket.on('delete_message', async ({ messageId, deleteType }) => {
      try {
        if (!messageId || typeof messageId !== 'string') return;
        const result = await require('../modules/chat/chat.service').deleteMessage(messageId, userId, deleteType);

        if (result.deleteType === 'for_everyone') {
          _io.to(result.chatId).emit('message_deleted', result);
        } else {
          socket.emit('message_deleted', result);
        }
      } catch (err) {
        socket.emit('error', { message: err.message || 'Failed to delete message' });
      }
    });

    // ─── EVENT: react_message ───────────────────────────
    socket.on('react_message', async ({ messageId, emoji }) => {
      try {
        if (!messageId || typeof messageId !== 'string') return;
        const result = await require('../modules/chat/chat.service').reactToMessage(messageId, userId, emoji);
        _io.to(result.chatId).emit('message_reacted', result);
      } catch (err) {
        socket.emit('error', { message: err.message || 'Failed to react to message' });
      }
    });

    // ─── EVENT: delete_chat ─────────────────────────────
    socket.on('delete_chat', async ({ chatId }) => {
      try {
        if (!chatId || typeof chatId !== 'string') return;
        const chat = await prisma.chat.findUnique({ where: { id: chatId } });
        if (!chat) return socket.emit('error', { message: 'Chat not found' });
        if (chat.renterId !== userId && chat.ownerId !== userId) {
          return socket.emit('error', { message: 'Unauthorized' });
        }

        await prisma.chat.delete({ where: { id: chatId } });
        _io.to(chatId).emit('chat_deleted', { chatId });
      } catch (err) {
        socket.emit('error', { message: 'Failed to delete chat' });
      }
    });

    socket.on('disconnect', () => {
      onlineUsers.delete(userId);
    });
  });

  return _io;
}

module.exports = { initSocket, getIO, onlineUsers };


