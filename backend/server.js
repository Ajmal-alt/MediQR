// backend/server.js
const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();
const authRoutes = require('./routes/auth');
const medicineRoutes = require('./routes/medicines');
const scanRoutes = require('./routes/scans');
const userRoutes = require('./routes/users');
const uploadRoutes = require('./routes/upload');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Serve video files statically
app.use('/videos', express.static(path.join(__dirname, 'videos')));
app.use('/images', express.static(path.join(__dirname, 'images')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/medicines', medicineRoutes);
app.use('/api/scans', scanRoutes);
app.use('/api/users', userRoutes);
app.use('/api/upload', uploadRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', version: '3.0.0', timestamp: new Date() });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`MediQR V3 API running on port ${PORT}`);
});