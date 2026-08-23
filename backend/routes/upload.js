// backend/routes/upload.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const { PutObjectCommand } = require('@aws-sdk/client-s3');
const { s3, BUCKET_NAME } = require('../config/s3');
const authMiddleware = require('../middleware/auth');

// Multer config - store in memory, upload to S3
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 100 * 1024 * 1024 }, // 100MB max
});

// Upload video to S3
router.post('/video', authMiddleware, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file uploaded' });

    const { medicine_id, language_code } = req.body;
    const ext = req.file.originalname.split('.').pop();
    const key = `videos/${medicine_id}_${language_code}.${ext}`;

    const command = new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
      Body: req.file.buffer,
      ContentType: req.file.mimetype,
      ACL: 'public-read',
    });

    await s3.send(command);

    const videoUrl = `https://${BUCKET_NAME}.s3.${process.env.AWS_REGION || 'us-east-1'}.amazonaws.com/${key}`;

    res.json({
      message: 'Video uploaded to S3',
      video_url: videoUrl,
      file_name: req.file.originalname,
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Upload failed' });
  }
});

// Upload image to S3
router.post('/image', authMiddleware, upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: 'No file uploaded' });

    const ext = req.file.originalname.split('.').pop();
    const key = `images/${Date.now()}_${req.file.originalname}`;

    const command = new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
      Body: req.file.buffer,
      ContentType: req.file.mimetype,
      ACL: 'public-read',
    });

    await s3.send(command);

    const imageUrl = `https://${BUCKET_NAME}.s3.${process.env.AWS_REGION || 'us-east-1'}.amazonaws.com/${key}`;

    res.json({
      message: 'Image uploaded to S3',
      image_url: imageUrl,
      file_name: req.file.originalname,
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: 'Upload failed' });
  }
});

module.exports = router;