const Redis = require('ioredis');

// Connect to Redis using the URL from environment variables
const redis = new Redis(process.env.REDIS_URL);

redis.on('connect', () => {
  console.log('✅ Redis connected successfully');
});

redis.on('error', (err) => {
  console.error('❌ Redis connection error:', err);
});

module.exports = redis;
