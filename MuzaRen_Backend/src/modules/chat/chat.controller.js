const chatService = require('./chat.service');

const createOrGetChat = async (req, res, next) => {
  try {
    const { listingId, ownerId } = req.body;
    const chat = await chatService.createOrGetChat(listingId, req.user.id, ownerId);
    res.status(200).json({ success: true, chat });
  } catch (error) {
    next(error);
  }
};

const getConversations = async (req, res, next) => {
  try {
    const conversations = await chatService.getConversations(req.user.id);
    res.status(200).json({ success: true, conversations });
  } catch (error) {
    next(error);
  }
};

const { getPaginationParams } = require('../../utils/paginate');

const getMessages = async (req, res, next) => {
  try {
    const { chatId } = req.params;
    const { page, limit } = getPaginationParams(req.query);
    const result = await chatService.getMessages(chatId, req.user.id, page, limit);
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    next(error);
  }
};

const uploadImage = async (req, res, next) => {
  try {
    // This assumes there's multer logic or similar in the route/middleware for file upload
    // Wait, the prompt says "Upload file to Cloudinary using existing Cloudinary config".
    // I need to adapt to where the file is. If the req hasn't been parsed for files,
    // I should check existing listings or users controller to see how files are handled.
    // For now I'll pass req.file or req.files safely into the service.
    
    if (!req.file && !req.files) return res.status(400).json({success: false, message: 'No image provided'});
    
    const file = req.file || (req.files && req.files.image && req.files.image[0]);
    if (!file) throw new Error('Invalid file payload');
    
    const replyToId = req.body.replyToId;
    const message = await chatService.uploadImage(req.params.chatId, req.user.id, file, replyToId);
    res.status(201).json({ success: true, message });
  } catch (error) {
    next(error);
  }
};

const markMessagesRead = async (req, res, next) => {
  try {
    const { chatId } = req.params;
    const updatedCount = await chatService.markMessagesRead(chatId, req.user.id);
    res.status(200).json({ success: true, updatedCount });
  } catch (error) {
    next(error);
  }
};

const editMessage = async (req, res, next) => {
  try {
    const { messageId } = req.params;
    const { text } = req.body;
    const message = await chatService.editMessage(messageId, req.user.id, text);
    res.status(200).json({ success: true, message });
  } catch (error) {
    next(error);
  }
};

const deleteMessage = async (req, res, next) => {
  try {
    const { messageId } = req.params;
    const { deleteType } = req.body;
    const result = await chatService.deleteMessage(messageId, req.user.id, deleteType);
    res.status(200).json({ success: true, result });
  } catch (error) {
    next(error);
  }
};

const deleteChat = async (req, res, next) => {
  try {
    const { chatId } = req.params;
    const result = await chatService.deleteChat(chatId, req.user.id);
    res.status(200).json({ success: true, result });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  createOrGetChat,
  getConversations,
  getMessages,
  uploadImage,
  markMessagesRead,
  editMessage,
  deleteMessage,
  deleteChat
};
