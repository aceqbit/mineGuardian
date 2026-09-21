// MineGuardian Backend — Main Entry Point
// Express + Socket.io + MongoDB + node-cron

require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const cron = require('node-cron');

const connectDB = require('./config/database');
const initFirebase = require('./config/firebase');
const { setupSocketHandlers } = require('./services/socket.service');
const { runShiftSLACheck } = require('./services/cron.service');

// Route imports
const authRoutes = require('./routes/auth.routes');
const checklistRoutes = require('./routes/checklist.routes');
const hazardRoutes = require('./routes/hazard.routes');
const supervisorRoutes = require('./routes/supervisor.routes');
const syncRoutes = require('./routes/sync.routes');

const app = express();
const server = http.createServer(app);

// Socket.io setup
const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || '*',
    methods: ['GET', 'POST'],
  },
});

// Make io accessible throughout app
app.set('io', io);

// Middleware
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(helmet({
  crossOriginResourcePolicy: false,
  crossOriginEmbedderPolicy: false,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('dev'));

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'MineGuardian API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/checklist', checklistRoutes);
app.use('/api/hazard', hazardRoutes);
app.use('/api/hazards', hazardRoutes);
app.use('/api/supervisor', supervisorRoutes);
app.use('/api/shifts', supervisorRoutes);
app.use('/api/sync', syncRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

// Setup Socket.io handlers
setupSocketHandlers(io);

// node-cron: Shift SLA check every 30 minutes
cron.schedule('*/30 * * * *', () => {
  console.log('[CRON] Running shift SLA check...');
  runShiftSLACheck();
});

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    // Initialize Firebase Admin
    initFirebase();
    
    // Connect to MongoDB
    await connectDB();
    
    server.listen(PORT, () => {
      console.log(`\n🛡️  MineGuardian API running on port ${PORT}`);
      console.log(`📡 Socket.io WebSocket server active`);
      console.log(`⏰ node-cron shift SLA timer active (every 30 min)\n`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

module.exports = { app, io };
