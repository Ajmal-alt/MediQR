// backend/routes/medicines.js
const express = require('express');
const router = express.Router();
const db = require('../config/db');
const authMiddleware = require('../middleware/auth');

// Get all medicines (protected)
router.get('/', authMiddleware, async (req, res) => {
  try {
    const [medicines] = await db.query('SELECT * FROM medicines');
    const result = await Promise.all(medicines.map(async (m) => {
      const [instructions] = await db.query(
        'SELECT language_code, instruction FROM medicine_instructions WHERE medicine_id = ?', [m.id]);
      const [videos] = await db.query(
        'SELECT language_code, video_url FROM videos WHERE medicine_id = ?', [m.id]);
      return {
        ...m,
        instructions: Object.fromEntries(instructions.map(i => [i.language_code, i.instruction])),
        video_urls: Object.fromEntries(videos.map(v => [v.language_code, v.video_url])),
      };
    }));
    res.json({ medicines: result });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get medicine by QR code (protected)
router.get('/qr/:qrCode', authMiddleware, async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM medicines WHERE qr_code = ?', [req.params.qrCode]);
    if (rows.length === 0) return res.status(404).json({ message: 'Medicine not found' });

    const m = rows[0];
    const [instructions] = await db.query(
      'SELECT language_code, instruction FROM medicine_instructions WHERE medicine_id = ?', [m.id]);
    const [videos] = await db.query(
      'SELECT language_code, video_url FROM videos WHERE medicine_id = ?', [m.id]);

    res.json({
      medicine: {
        ...m,
        instructions: Object.fromEntries(instructions.map(i => [i.language_code, i.instruction])),
        video_urls: Object.fromEntries(videos.map(v => [v.language_code, v.video_url])),
      }
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Server error' });
  }
});

// Add video URL for a medicine (pharmacist only)
router.post('/:id/videos', authMiddleware, async (req, res) => {
  const { language_code, video_url, file_name } = req.body;
  try {
    await db.query(
      'INSERT INTO videos (medicine_id, language_code, video_url, file_name) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE video_url = ?, file_name = ?',
      [req.params.id, language_code, video_url, file_name, video_url, file_name]
    );
    res.json({ message: 'Video URL saved' });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
