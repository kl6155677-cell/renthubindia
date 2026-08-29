const { verifyAccessToken } = require('../utils/jwt');
const redis = require('../config/redis');
const prisma = require('../config/db');

const auth = async (req, res, next) => {
  try {
    const authHeader = req.header('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'No token, authorization denied' });
    }

    const token = authHeader.replace('Bearer ', '');

    // Check if token is blacklisted (revoked via logout)
    const isBlacklisted = await redis.get(`blacklist:${token}`);
    if (isBlacklisted) {
      return res.status(401).json({ success: false, message: 'Token has been revoked' });
    }

    const decoded = verifyAccessToken(token);
    
    // Circuit Breaker: Kill session immediately if Account is Blocked
    const user = await prisma.user.findUnique({
      where: { id: decoded.id },
      select: { id: true, role: true, isBlocked: true }
    });

    if (!user) {
      return res.status(401).json({ success: false, message: 'User not found' });
    }
    if (user.isBlocked) {
      return res.status(403).json({ success: false, message: 'Account suspended - action prohibited' });
    }

    // Attach decoded JWT payload + fresh role from DB
    req.user = { id: decoded.id, role: user.role };
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ 
        success: false, 
        message: 'Token has expired',
        code: 'TOKEN_EXPIRED' // Flutter uses this code to trigger refresh
      });
    }
    return res.status(401).json({ success: false, message: 'Token is not valid' });
  }
};

module.exports = auth;
