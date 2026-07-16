// backend/routes/scans.js
const express = require('express');
const router = express.Router();
const db = require('../config/db');
const authMiddleware = require('../middleware/auth');

// Log a scan
router.post('/', authMiddleware, async (req, res) => {
  const { qr_code, medicine_id } = req.body;
  try {
    await db.query(
      'INSERT INTO scan_logs (user_id, medicine_id, qr_code) VALUES (?, ?, ?)',
      [req.user.id, medicine_id || null, qr_code]
    );
    res.json({ message: 'Scan logged' });
  } catch (e) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Get user scan history
router.get('/history', authMiddleware, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT s.id, s.qr_code, s.scanned_at, m.name AS medicine_name
       FROM scan_logs s
       LEFT JOIN medicines m ON s.medicine_id = m.id
       WHERE s.user_id = ?
       ORDER BY s.scanned_at DESC
       LIMIT 50`,
      [req.user.id]
    );
    res.json({ history: rows });
  } catch (e) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Admin: all scans
router.get('/all', authMiddleware, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ message: 'Forbidden' });
  try {
    const [rows] = await db.query(
      `SELECT s.*, u.name AS user_name, m.name AS medicine_name
       FROM scan_logs s
       LEFT JOIN users u ON s.user_id = u.id
       LEFT JOIN medicines m ON s.medicine_id = m.id
       ORDER BY s.scanned_at DESC LIMIT 200`
    );
    res.json({ scans: rows });
  } catch (e) {
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
