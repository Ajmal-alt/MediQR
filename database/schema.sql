-- MediQR V3 Database Schema
-- Run: mysql -u root -p < schema.sql

CREATE DATABASE IF NOT EXISTS mediqr3;
USE mediqr3;

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('patient', 'pharmacist', 'admin') DEFAULT 'patient',
  preferred_language VARCHAR(5) DEFAULT 'en',
  profile_image VARCHAR(255),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Medicines table
CREATE TABLE IF NOT EXISTS medicines (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  qr_code VARCHAR(255) UNIQUE NOT NULL,
  description TEXT,
  category VARCHAR(50) DEFAULT 'General',
  dosage TEXT,
  side_effects TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Medicine instructions per language
CREATE TABLE IF NOT EXISTS medicine_instructions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  medicine_id INT NOT NULL,
  language_code VARCHAR(5) NOT NULL,
  instruction TEXT NOT NULL,
  FOREIGN KEY (medicine_id) REFERENCES medicines(id) ON DELETE CASCADE,
  UNIQUE KEY unique_med_lang (medicine_id, language_code)
);

-- Videos table
CREATE TABLE IF NOT EXISTS videos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  medicine_id INT NOT NULL,
  language_code VARCHAR(5) NOT NULL,
  video_url VARCHAR(500) NOT NULL,
  file_name VARCHAR(255),
  uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (medicine_id) REFERENCES medicines(id) ON DELETE CASCADE,
  UNIQUE KEY unique_video (medicine_id, language_code)
);

-- Scan logs
CREATE TABLE IF NOT EXISTS scan_logs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT,
  medicine_id INT,
  qr_code VARCHAR(255),
  scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (medicine_id) REFERENCES medicines(id) ON DELETE SET NULL
);

-- Sample medicines
INSERT INTO medicines (name, qr_code, description, category, dosage, side_effects) VALUES
('Paracetamol', 'MED-PARA-001', 'Pain reliever and fever reducer', 'Analgesic', '500mg every 4-6 hours. Max 4g/day', 'Nausea, rash (rare). Avoid alcohol'),
('Amoxicillin', 'MED-AMOX-001', 'Antibiotic for bacterial infections', 'Antibiotic', '250-500mg every 8 hours for 5-7 days', 'Diarrhea, rash, allergic reaction'),
('Metformin', 'MED-METF-001', 'Controls blood sugar in type 2 diabetes', 'Antidiabetic', '500mg twice daily with meals', 'Nausea, diarrhea, stomach upset'),
('ORS', 'MED-ORS-001', 'Oral Rehydration Salts for dehydration', 'Rehydration', 'Dissolve 1 sachet in 1L water. Drink slowly', 'Generally safe. Avoid if kidney failure'),
('Iron+Folic Acid', 'MED-IRON-001', 'Iron and folic acid supplement', 'Supplement', '1 tablet daily after food', 'Dark stools, constipation, nausea');

-- Sample instructions (English)
INSERT INTO medicine_instructions (medicine_id, language_code, instruction) VALUES
(1, 'en', 'Take 1-2 tablets every 4-6 hours as needed for pain or fever. Do not exceed 8 tablets in 24 hours.'),
(2, 'en', 'Take as prescribed by your doctor. Complete the full course even if feeling better.'),
(3, 'en', 'Take with food to reduce stomach upset. Never skip doses. Monitor blood sugar regularly.'),
(4, 'en', 'Mix one sachet in 1 litre of clean water. Give small sips frequently. Continue until diarrhea stops.'),
(5, 'en', 'Take one tablet daily after food. Best absorbed with Vitamin C. May cause dark stools - this is normal.');

-- Sample instructions (Tamil)
INSERT INTO medicine_instructions (medicine_id, language_code, instruction) VALUES
(1, 'ta', 'வலி அல்லது காய்ச்சலுக்கு 4-6 மணி நேரத்திற்கு ஒரு முறை 1-2 மாத்திரை எடுக்கவும்.'),
(2, 'ta', 'மருத்துவர் பரிந்துரைத்தபடி எடுக்கவும். நலமடைந்தாலும் முழு கோர்ஸ் முடிக்கவும்.'),
(3, 'ta', 'வயிற்று உபாதை குறைக்க உணவுடன் எடுக்கவும். இரத்த சர்க்கரையை கண்காணிக்கவும்.'),
(4, 'ta', 'ஒரு பாக்கெட்டை 1 லிட்டர் தூய தண்ணீரில் கலக்கவும். அடிக்கடி சிறிய சிப்பில் குடிக்கவும்.'),
(5, 'ta', 'உணவுக்கு பின் ஒரு மாத்திரை எடுக்கவும். கருப்பு மலம் சாதாரணமானது.');

-- Note: Add video URLs after uploading videos to server
-- UPDATE videos SET video_url = 'http://YOUR_IP:3000/videos/filename.mp4' WHERE ...;
