const jwt = require('jsonwebtoken');

const ACCESS_TOKEN_SECRET  = process.env.JWT_SECRET;
const REFRESH_TOKEN_SECRET = process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET;
const ACCESS_EXPIRES       = '15m';   // 15 minutes only
const REFRESH_EXPIRES      = '30d';   // 30 days

function generateAccessToken(payload) {
  return jwt.sign(payload, ACCESS_TOKEN_SECRET, {
    expiresIn: ACCESS_EXPIRES,
    issuer: 'renthubindia-api',
    audience: 'renthubindia-app',
  });
}

function generateRefreshToken(payload) {
  return jwt.sign(payload, REFRESH_TOKEN_SECRET, {
    expiresIn: REFRESH_EXPIRES,
    issuer: 'renthubindia-api',
    audience: 'renthubindia-app',
  });
}

function verifyAccessToken(token) {
  return jwt.verify(token, ACCESS_TOKEN_SECRET, {
    issuer: 'renthubindia-api',
    audience: 'renthubindia-app',
  });
}

function verifyRefreshToken(token) {
  return jwt.verify(token, REFRESH_TOKEN_SECRET, {
    issuer: 'renthubindia-api',
    audience: 'renthubindia-app',
  });
}

// Backward-compat aliases (used by socket.js and other modules during migration)
const signToken = (userId) => generateAccessToken({ id: userId });
const verifyToken = (token) => verifyAccessToken(token);

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
  signToken,
  verifyToken,
};
