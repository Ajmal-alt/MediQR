// backend/routes/auth.js
const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const { SECRET } = require('../middleware/auth');

// Register
router.post('/register', async (req, res) => {
  const { name, phone, email, password, role, preferred_language } = req.body;
  if (!name || !email || !password) {
    return res.status(400).json({ message: 'Name, email and password are required' });
  }
  try {
    const [existing] = await db.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(409).json({ message: 'Email already registered' });
    }
    const hash = await bcrypt.hash(password, 10);
    const [result] = await db.query(
      'INSERT INTO users (name, phone, email, password_hash, role, preferred_language) VALUES (?, ?, ?, ?, ?, ?)',
      [name, phone || '', email, hash, role || 'patient', preferred_language || 'en']
    );
    const user = { id: result.insertId, name, email, phone, role: role || 'patient', preferred_language: preferred_language || 'en' };
    const token = jwt.sign({ id: user.id, email, role: user.role }, SECRET, { expiresIn: '30d' });
    res.status(201).json({ token, user });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Server error' });
  }
});

// Login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password required' });
  }
  try {
    const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email]);
    if (rows.length === 0) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    const user = rows[0];
    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }
    const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, SECRET, { expiresIn: '30d' });
    const userData = {
      id: user.id, name: user.name, email: user.email,
      phone: user.phone, role: user.role, preferred_language: user.preferred_language,
    };
    res.json({ token, user: userData });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
