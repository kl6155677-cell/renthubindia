const { messaging } = require('../config/firebase');

const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  if (!fcmToken) {
    console.log('Skipping FCM. Token missing.');
    return null;
  }

  // FCM data messages insist all payload values be strings.
  const stringifiedData = {};
  for (const [key, value] of Object.entries(data)) {
    stringifiedData[key] = String(value);
  }

  const message = {
    token: fcmToken,
    notification: {
      title,
      body,
    },
    data: stringifiedData,
  };

  try {
    const response = await messaging.send(message);
    return response;
  } catch (error) {
    console.error('Error sending message:', error);
    return null;
  }
};

module.exports = {
  sendPushNotification,
};
