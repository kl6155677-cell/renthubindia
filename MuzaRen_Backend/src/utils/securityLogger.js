/**
 * Structured security event logger for RentHubIndia.
 * In production, replace console with a logging service (Winston, Datadog, etc.)
 */
const SecurityLogger = {
  loginSuccess(userId, ip) {
    console.log(JSON.stringify({
      event: 'LOGIN_SUCCESS', userId, ip,
      timestamp: new Date().toISOString()
    }));
  },

  loginFailed(email, ip, attempts) {
    console.warn(JSON.stringify({
      event: 'LOGIN_FAILED', email, ip, attempts,
      timestamp: new Date().toISOString()
    }));
  },

  accountLocked(email, ip) {
    console.warn(JSON.stringify({
      event: 'ACCOUNT_LOCKED', email, ip,
      timestamp: new Date().toISOString()
    }));
  },

  tokenRevoked(userId, reason) {
    console.log(JSON.stringify({
      event: 'TOKEN_REVOKED', userId, reason,
      timestamp: new Date().toISOString()
    }));
  },

  unauthorizedAccess(userId, resource, ip) {
    console.warn(JSON.stringify({
      event: 'UNAUTHORIZED_ACCESS', userId, resource, ip,
      timestamp: new Date().toISOString()
    }));
  },

  adminAction(adminId, action, targetId) {
    console.log(JSON.stringify({
      event: 'ADMIN_ACTION', adminId, action, targetId,
      timestamp: new Date().toISOString()
    }));
  },

  suspiciousActivity(description, details) {
    console.error(JSON.stringify({
      event: 'SUSPICIOUS_ACTIVITY', description, details,
      timestamp: new Date().toISOString()
    }));
  },
};

module.exports = SecurityLogger;
