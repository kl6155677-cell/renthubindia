const express = require('express');
const chatController = require('./chat.controller');
const authMiddleware = require('../../middleware/auth');
const { singleImageUpload } = require('../../config/cloudinary');

const router = express.Router();

// All chat routes require authentication
router.use(authMiddleware);

router.post('/', chatController.createOrGetChat);
router.get('/conversations', chatController.getConversations);
router.get('/:chatId/messages', chatController.getMessages);
router.post('/:chatId/upload', singleImageUpload, chatController.uploadImage);
router.patch('/:chatId/read', chatController.markMessagesRead);
router.patch('/messages/:messageId', chatController.editMessage);
router.delete('/messages/:messageId', chatController.deleteMessage);
router.delete('/:chatId', chatController.deleteChat);

module.exports = router;
