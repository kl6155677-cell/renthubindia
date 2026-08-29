const ADMIN_ROLES = ['ADMIN', 'SUPER_ADMIN', 'MODERATOR'];

const requireAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ success: false, message: 'Not authenticated' });
  }
  
  if (!ADMIN_ROLES.includes(req.user.role)) {
    return res.status(403).json({ success: false, message: 'Admin access required' });
  }
  
  next();
};


module.exports = {
  requireAdmin
};
