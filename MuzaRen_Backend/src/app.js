const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const hpp = require('hpp');
const errorHandler = require('./middleware/errorHandler');
const swaggerUi = require('swagger-ui-express');
const swaggerSpecs = require('./config/swagger');
const { apiLimiter } = require('./middleware/rateLimit');

const app = express();
app.set('trust proxy', 1); // Required for Railway/Proxies
app.disable('x-powered-by'); // Don't reveal Express

// ── SECURITY HEADERS ──────────────────────────────────────
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc:  ["'self'"],
      styleSrc:   ["'self'", "'unsafe-inline'"],
      imgSrc:     ["'self'", 'data:', 'https://res.cloudinary.com'],
      connectSrc: ["'self'"],
      frameSrc:   ["'none'"],
      objectSrc:  ["'none'"],
    },
  },
  hsts: {
    maxAge: 31536000,        // 1 year
    includeSubDomains: true,
    preload: true,
  },
  noSniff: true,             // X-Content-Type-Options: nosniff
  xssFilter: true,           // X-XSS-Protection
  frameguard: { action: 'deny' }, // X-Frame-Options: DENY
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
}));

// ── CORS ──────────────────────────────────────────────────
// Parse ALLOWED_ORIGINS from environment, fallback to localhost for dev
const allowedOrigins = process.env.ALLOWED_ORIGINS 
  ? process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim())
  : [
      'http://localhost:3000',   // Mobile web / React app
      'http://localhost:5000',   // Backend self
      'http://localhost:5173',   // Admin panel (Vite dev server)
      'http://127.0.0.1:5173',   // Admin panel (IPv4 fallback)
      'https://muza-renn.vercel.app', // Production Admin Panel (Vercel)
    ];

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps), allowed list, dynamic FRONTEND_URL, and any Vercel app (for testing)
    if (
      !origin || 
      allowedOrigins.includes(origin) || 
      origin === process.env.FRONTEND_URL ||
      origin.endsWith('.vercel.app')
    ) {
      callback(null, true);
    } else {
      callback(new Error(`CORS: Origin ${origin} not allowed`));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400, // 24 hours preflight cache
}));

// Request Logging
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// ── BODY PARSING ─────────────────────────────────────────
app.use(express.json({ limit: '10kb' })); // Prevent huge JSON payloads
app.use(express.urlencoded({ extended: true, limit: '10kb' }));

// ── PREVENT HTTP PARAMETER POLLUTION ─────────────────────
app.use(hpp());

// ── GENERAL API RATE LIMIT ───────────────────────────────
app.use('/api', apiLimiter);

// ---------------------------------------------------------
// MOUNT ROUTERS
// ---------------------------------------------------------
// Serve visual documentation statically under /api-docs recursively
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpecs));
app.use('/api/auth', require('./modules/auth/auth.routes'));
app.use('/api/users', require('./modules/users/users.routes'));
app.use('/api/categories', require('./modules/categories/categories.routes'));
app.use('/api/listings', require('./modules/listings/listings.routes'));
app.use('/api/bookings', require('./modules/bookings/bookings.routes'));
app.use('/api/reviews', require('./modules/reviews/reviews.routes'));
app.use('/api/reports', require('./modules/reports/reports.routes'));
app.use('/api/notifications', require('./modules/notifications/notifications.routes'));
app.use('/api/support', require('./modules/support/support.routes'));
app.use('/api/admin', require('./modules/admin/admin.routes'));
app.use('/api/chat', require('./modules/chat/chat.routes'));
app.use('/api/cities', require('./modules/cities/cities.routes'));

// Basic health-check endpoint for server pings
app.get('/api/health', (req, res) => {
  res.status(200).json({ success: true, message: 'Welcome to the RentHubIndia API!' });
});

// ---------------------------------------------------------

// Global Error Handler - must always be the final mounted middleware
app.use(errorHandler);

module.exports = app;
