require('dotenv').config();
const app = require('./src/app');
const prisma = require('./src/config/db');
const { initSocket } = require('./src/config/socket');
const http = require('http');

// Ensure Redis configs load
require('./src/config/redis');

// Ensure Firebase is initialized
require('./src/config/firebase');

const PORT = process.env.PORT || 5000;

// Create HTTP server from Express app
const httpServer = http.createServer(app);

// Attach Socket.IO to the HTTP server
initSocket(httpServer);

// Start HTTP server (works for Railway, local dev, and any persistent host)
const startServer = async () => {
  try {
    await prisma.$connect();
    console.log('✅ Database connected successfully');
    httpServer.listen(PORT, () => {
      console.log(`🚀 RentHubIndia Backend Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('❌ Critical Failure! Unable to start the server:');
    console.error(error);
    process.exit(1);
  }
};

startServer();

// Export for serverless runtimes (e.g. Vercel) if needed
module.exports = httpServer;
