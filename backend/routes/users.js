// backend/routes/users.js
const express = require('express');
const router = express.Router();
const db = require('../config/db');
const authMiddleware = require('../middleware/auth');

// Get my profile
router.get('/profile', authMiddleware, async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT id, name, phone, email, role, preferred_language, profile_image, created_at FROM users WHERE id = ?',
      [req.user.id]
    );
    if (rows.length === 0) return res.status(404).json({ message: 'User not found' });
    res.json({ user: rows[0] });
  } catch (e) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Update profile
router.put('/profile', authMiddleware, async (req, res) => {
  const { name, phone, preferred_language } = req.body;
  try {
    await db.query(
      'UPDATE users SET name = ?, phone = ?, preferred_language = ? WHERE id = ?',
      [name, phone, preferred_language, req.user.id]
    );
    const [rows] = await db.query(
      'SELECT id, name, phone, email, role, preferred_language FROM users WHERE id = ?',
      [req.user.id]
    );
    res.json({ user: rows[0] });
  } catch (e) {
    res.status(500).json({ message: 'Server error' });
  }
});

// Admin: get all users
router.get('/all', authMiddleware, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ message: 'Forbidden' });
  try {
    const [rows] = await db.query(
      'SELECT id, name, phone, email, role, preferred_language, created_at FROM users ORDER BY created_at DESC'
    );
    res.json({ users: rows });
  } catch (e) {
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
