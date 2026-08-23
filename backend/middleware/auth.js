// backend/middleware/auth.js
const jwt = require('jsonwebtoken');
require('dotenv').config();

const SECRET = process.env.JWT_SECRET || 'mediqr_v3_secret_key_change_in_production';

module.exports = (req, res, next) => {
  const header = req.headers['authorization'];
  if (!header) return res.status(401).json({ message: 'No token provided' });

  const token = header.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Invalid token format' });

  try {
    const decoded = jwt.verify(token, SECRET);
    req.user = decoded;
    next();
  } catch (e) {
    return res.status(401).json({ message: 'Token expired or invalid' });
  }
};

module.exports.SECRET = SECRET;