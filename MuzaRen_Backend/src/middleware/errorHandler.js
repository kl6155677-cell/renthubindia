const SecurityLogger = require('../utils/securityLogger');

function errorHandler(err, req, res, next) {
  // Log the full error internally (never expose to client)
  const errorContext = {
    timestamp: new Date().toISOString(),
    method: req.method,
    url: req.originalUrl,
    userId: req.user?.id,
    ip: req.ip || req.connection.remoteAddress,
    error: err.message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
  };
  
  if (err.statusCode && err.statusCode < 500) {
    console.warn(JSON.stringify(errorContext));
  } else {
    console.error(JSON.stringify(errorContext));
  }

  // Handle malformed JSON syntax errors
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return res.status(400).json({ success: false, message: 'Invalid JSON payload' });
  }

  // Handle Zod Validation Errors
  if (err.name === 'ZodError') {
    const errors = (err.issues || err.errors || []).map(e => ({
      field: e.path.join('.'),
      message: e.message
    }));
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors
    });
  }

  // Handle Prisma errors — never expose DB schema to client
  if (err.code && err.code.startsWith('P')) {
    if (err.code === 'P2002') {
      return res.status(409).json({ success: false, message: 'This record already exists' });
    }
    if (err.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Record not found' });
    }
    return res.status(500).json({ success: false, message: 'Database constraint violation' });
  }

  // Handle CORS errors
  if (err.message && err.message.includes('CORS')) {
    SecurityLogger.unauthorizedAccess(req.user?.id || 'anonymous', 'CORS violation', errorContext.ip);
    return res.status(403).json({ success: false, message: 'Origin not allowed by CORS' });
  }

  // Handle Multer upload errors
  if (err.name === 'MulterError') {
    return res.status(400).json({ success: false, message: `Upload error: ${err.message}` });
  }

  // Default error — never expose stack trace in production
  const statusCode = err.statusCode || err.status || 500;
  const message = process.env.NODE_ENV === 'production' 
    ? (statusCode < 500 ? err.message : 'Internal server error') 
    : err.message;

  return res.status(statusCode).json({ success: false, message });
}

module.exports = errorHandler;
