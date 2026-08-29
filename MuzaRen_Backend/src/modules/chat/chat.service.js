const prisma = require('../../config/db');
const { getIO } = require('../../config/socket');
const { sendNotification } = require('../../utils/notifications');
const crypto = require('crypto');

const createOrGetChat = async (listingId, userId, otherUserId) => {
  // 1. Get the listing to identify the real owner
  const listing = await prisma.listing.findUnique({
    where: { id: listingId },
    select: { userId: true }
  });

  if (!listing) throw new Error('Listing not found');

  const realOwnerId = listing.userId;
  // The renter is whoever is NOT the owner
  const realRenterId = (userId === realOwnerId) ? otherUserId : userId;

  // 2. SEARCH AGGRESSIVELY: Find any chat between these two users for this listing
  let chat = await prisma.chat.findFirst({
    where: {
      listingId,
      OR: [
        { AND: [{ renterId: realRenterId }, { ownerId: realOwnerId }] },
        { AND: [{ renterId: realOwnerId }, { ownerId: realRenterId }] }
      ]
    }
  });

  if (!chat) {
    try {
      chat = await prisma.chat.create({
        data: {
          listingId,
          renterId: realRenterId,
          ownerId: realOwnerId
        }
      });
    } catch (err) {
      // 3. LAST RESORT: If creation still fails (e.g. race condition), try finding it one last time
      chat = await prisma.chat.findFirst({
        where: {
          listingId,
          OR: [
            { AND: [{ renterId: realRenterId }, { ownerId: realOwnerId }] },
            { AND: [{ renterId: realOwnerId }, { ownerId: realRenterId }] }
          ]
        }
      });
      if (!chat) throw err;
    }
  }

  return chat;
};

const getConversations = async (userId) => {
  const chats = await prisma.chat.findMany({
    where: {
      AND: [
        { OR: [{ renterId: userId }, { ownerId: userId }] },
        { NOT: { deletedBy: { has: userId } } }
      ]
    },
    include: {
      listing: { select: { title: true, pricePerDay: true, images: { take: 1, orderBy: { sortOrder: 'asc' } } } },
      renter: { select: { id: true, name: true, avatarUrl: true, verificationStatus: true } },
      owner: { select: { id: true, name: true, avatarUrl: true, verificationStatus: true } },
      messages: {
        orderBy: { createdAt: 'desc' },
        take: 1
      },
      _count: {
        select: {
          messages: {
            where: {
              senderId: { not: userId },
              read: false
            }
          }
        }
      }
    },
    orderBy: { updatedAt: 'desc' }
  });

  const conversationMap = new Map();

  for (const chat of chats) {
    const isOwner = chat.ownerId === userId;
    const otherUser = isOwner ? chat.renter : chat.owner;
    
    // Create a unique key for this listing + the pair of users
    const key = `${chat.listingId}_${otherUser.id}`;
    
    // If we already have a conversation for this pair, only keep the one with the latest message
    if (conversationMap.has(key)) {
      continue; // Skip the older one (since 'chats' is ordered by updatedAt)
    }

    const lastMessage = chat.messages.length > 0 ? chat.messages[0] : null;

    conversationMap.set(key, {
      id: chat.id,
      listingId: chat.listingId,
      listingTitle: chat.listing.title,
      listingPrice: chat.listing.pricePerDay,
      listingImageUrl: chat.listing.images.length > 0 ? chat.listing.images[0].imageUrl : null,
      otherUserId: otherUser.id,
      otherUserName: otherUser.name,
      otherUserAvatarUrl: otherUser.avatarUrl,
      otherUserVerified: otherUser.verificationStatus === 'VERIFIED',
      lastMessageText: lastMessage ? lastMessage.text : null,
      lastMessageImageUrl: lastMessage ? lastMessage.imageUrl : null,
      lastMessageAt: lastMessage ? lastMessage.createdAt : null,
      unreadCount: chat._count.messages
    });
  }

  return Array.from(conversationMap.values());
};

const { paginate } = require('../../utils/paginate');

const getMessages = async (chatId, userId, page = 1, limit = 50) => {
  // Fast verification: only select IDs
  const chat = await prisma.chat.findUnique({
    where: { id: chatId },
    select: { renterId: true, ownerId: true }
  });

  if (!chat) throw new Error('Chat not found');
  if (chat.renterId !== userId && chat.ownerId !== userId) {
    throw new Error('Unauthorized');
  }

  return paginate({
    modelName: 'message',
    where: {
      chatId,
      NOT: { deletedForSelf: { has: userId } },
    },
    include: {
      sender: { select: { id: true, name: true, avatarUrl: true } },
      replyTo: {
        select: {
          id: true,
          text: true,
          imageUrl: true,
          sender: { select: { name: true } },
        },
      },
    },
    orderBy: { createdAt: 'desc' }, // Latest first for pagination logic, then reversed in frontend if needed
    page,
    limit,
  });
};

const uploadImage = async (chatId, userId, file, replyToId) => {
  const chat = await prisma.chat.findUnique({
    where: { id: chatId },
    include: {
      renter: { select: { id: true, name: true } },
      owner: { select: { id: true, name: true } }
    }
  });
  if (!chat) throw new Error('Chat not found');
  if (chat.renterId !== userId && chat.ownerId !== userId) {
    throw new Error('Unauthorized');
  }

  // File is already uploaded via Cloudinary multer middleware (so file.path contains URL)
  const imageUrl = file.path;
  const messageId = crypto.randomUUID();
  const now = new Date();

  let replyToData = null;
  if (replyToId && typeof replyToId === 'string') {
    replyToData = await prisma.message.findUnique({
      where: { id: replyToId },
      select: { id: true, text: true, imageUrl: true, sender: { select: { name: true } } }
    });
  }

  const senderInfo = chat.renterId === userId ? chat.renter : chat.owner;
  const receiverId = chat.renterId === userId ? chat.ownerId : chat.renterId;

  const optimisticMessage = {
    id: messageId,
    chatId,
    senderId: userId,
    imageUrl,
    read: false,
    replyToId: replyToId || null,
    createdAt: now,
    updatedAt: now,
    sender: { id: senderInfo.id, name: senderInfo.name, avatarUrl: senderInfo.avatarUrl || null },
    replyTo: replyToData
  };

  const io = getIO();
  // ── BROADCAST TO CHAT ROOM ───────────────────────────────
  // Ensure the image bubble appears instantly for the receiver BEFORE DB write
  io.to(chatId).emit('new_message', { message: optimisticMessage });

  try {
    const savedMessage = await prisma.message.create({
      data: {
        id: messageId,
        chatId,
        senderId: userId,
        imageUrl,
        read: false,
        replyToId: replyToId || null,
        createdAt: now,
        updatedAt: now
      },
      include: {
        sender: { select: { id: true, name: true, avatarUrl: true } },
        replyTo: {
          select: {
            id: true,
            text: true,
            imageUrl: true,
            sender: { select: { name: true } }
          }
        }
      }
    });

    // ── SECONDARY OPERATIONS ────────────────
    await prisma.chat.update({
      where: { id: chatId },
      data: { updatedAt: now }
    });

    // ── TRIGGER NOTIFICATION (Non-blocking) ───────────────
    sendNotification(io, {
      userId: receiverId,
      title: senderInfo.name,
      body: '📷 Sent you a photo',
      type: 'new_message',
      data: { chatId }
    }).catch(err => console.error('Error sending notification:', err));

    return savedMessage;
  } catch (err) {
    console.error('Critical Error saving image message, rolling back:', err);
    io.to(chatId).emit('message_deleted', { id: messageId, chatId, deleteType: 'for_everyone' });
    throw new Error('Database error during image upload, message removed.');
  }
};

const markMessagesRead = async (chatId, userId) => {
  const result = await prisma.message.updateMany({
    where: {
      chatId,
      senderId: { not: userId },
      read: false
    },
    data: {
      read: true
    }
  });

  return result.count;
};

const editMessage = async (messageId, userId, newText) => {
  if (!newText || !newText.trim()) {
    throw new Error('Message cannot be empty');
  }

  const message = await prisma.message.findUnique({
    where: { id: messageId },
    select: { senderId: true, chatId: true, createdAt: true, imageUrl: true }
  });

  if (!message) throw new Error('Message not found');
  if (message.senderId !== userId) throw new Error('Unauthorized');
  if (message.imageUrl) throw new Error('Cannot edit image messages');

  // Check 15 minute limit
  const minutesDiff = (Date.now() - new Date(message.createdAt).getTime()) / 60000;
  if (minutesDiff > 15) {
    throw new Error('Can only edit messages within 15 minutes');
  }

  return await prisma.message.update({
    where: { id: messageId },
    data: {
      text: newText.trim(),
      editedAt: new Date()
    },
    include: { sender: { select: { id: true, name: true, avatarUrl: true } } }
  });
};

const deleteMessage = async (messageId, userId, deleteType) => {
  const message = await prisma.message.findUnique({
    where: { id: messageId },
    select: { senderId: true, chatId: true, createdAt: true }
  });

  if (!message) throw new Error('Message not found');
  if (message.senderId !== userId) throw new Error('Unauthorized');

  if (deleteType === 'for_everyone') {
    // Check 24 hour limit
    const hoursDiff = (Date.now() - new Date(message.createdAt).getTime()) / 3600000;
    if (hoursDiff > 24) {
      throw new Error('Can only delete for everyone within 24 hours');
    }

    await prisma.message.update({
      where: { id: messageId },
      data: { deletedForAll: true, text: null, imageUrl: null }
    });

    return { id: messageId, chatId: message.chatId, deleteType: 'for_everyone' };
  } else {
    // Delete for self only
    await prisma.message.update({
      where: { id: messageId },
      data: { deletedForSelf: { push: userId } }
    });

    return { id: messageId, chatId: message.chatId, deleteType: 'for_me' };
  }
};

const deleteChat = async (chatId, userId) => {
  const chat = await prisma.chat.findUnique({
    where: { id: chatId },
    select: { renterId: true, ownerId: true }
  });

  if (!chat) throw new Error('Chat not found');
  if (chat.renterId !== userId && chat.ownerId !== userId) {
    throw new Error('Unauthorized');
  }

  const updatedChat = await prisma.chat.update({
    where: { id: chatId },
    data: { deletedBy: { push: userId } }
  });

  // Optional: Physical delete if both sides 'deleted' it
  if (updatedChat.deletedBy.length >= 2) {
    await prisma.chat.delete({ where: { id: chatId } });
  }

  return { id: chatId };
};

const reactToMessage = async (messageId, userId, emoji) => {
  const message = await prisma.message.findUnique({
    where: { id: messageId },
    select: { reactions: true, chatId: true }
  });

  if (!message) throw new Error('Message not found');

  const reactions = typeof message.reactions === 'object' ? { ...message.reactions } : {};

  if (reactions[userId] === emoji) {
    delete reactions[userId]; // Toggle off if same emoji
  } else {
    reactions[userId] = emoji;
  }

  const updatedMessage = await prisma.message.update({
    where: { id: messageId },
    data: { reactions },
    include: { sender: { select: { id: true, name: true, avatarUrl: true } } }
  });

  return {
    messageId,
    chatId: message.chatId,
    reactions: updatedMessage.reactions,
    userId,
    emoji
  };
};

module.exports = {
  createOrGetChat,
  getConversations,
  getMessages,
  uploadImage,
  markMessagesRead,
  editMessage,
  deleteMessage,
  deleteChat,
  reactToMessage
};
