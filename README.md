# MediQR V3 — Rural Patient Medicine QR Scanner

![MediQR Logo](assets/images/logo.png)

**Version:** 3.0.0  
**License:** MIT

---

## What's New in V3

| Feature | V1 | V2 | V3 |
|---|---|---|---|
| QR Scanner | ✅ Simulated | ✅ Real | ✅ Real |
| Backend | ❌ None | ✅ Node.js | ✅ Node.js + Auth |
| Database | ❌ Dart hardcoded | ✅ MySQL | ✅ MySQL + Users |
| Video Player | ❌ Simulated | ✅ Chewie | ✅ Chewie |
| Offline Cache | ❌ None | ✅ SQLite | ✅ SQLite |
| User Login | ❌ None | ❌ None | ✅ JWT Auth |
| User Profiles | ❌ None | ❌ None | ✅ Full profile |
| Scan History | ❌ None | ❌ None | ✅ Per user |
| Bluetooth | ✅ Simulated | ✅ Real | ✅ Real |
| Languages | 4 | 4 | 4 |
| Medicines | 5 | 5 | 5 |

---

## Project Structure

```
mediqr3/
├── lib/
│   ├── main.dart                  # App entry + splash + auth gate
│   ├── models/
│   │   ├── user_model.dart
│   │   └── medicine_model.dart
│   ├── services/
│   │   ├── auth_service.dart      # JWT login/register/logout
│   │   ├── medicine_service.dart  # API + offline fallback
│   │   └── local_db_service.dart  # SQLite cache + history
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── home_screen.dart
│   │   ├── qr_scanner_screen.dart
│   │   ├── medicine_detail_screen.dart
│   │   ├── my_videos_screen.dart
│   │   ├── transfer_screen.dart
│   │   └── profile_screen.dart
│   └── utils/
│       └── app_config.dart        # ⚠️ Set baseUrl here
├── backend/
│   ├── server.js
│   ├── package.json
│   ├── config/db.js
│   ├── middleware/auth.js
│   ├── routes/
│   │   ├── auth.js
│   │   ├── medicines.js
│   │   ├── scans.js
│   │   └── users.js
│   └── videos/                    # Put .mp4 files here
├── database/
│   └── schema.sql
├── assets/
│   ├── images/logo.png
│   └── videos/mediqr_intro_tam.mp4
└── pubspec.yaml
```

---

## Setup Guide

### Step 1 — MySQL Database

```bash
mysql -u root -p < database/schema.sql
```

### Step 2 — Backend

```bash
cd backend
npm install
node server.js
```

### Step 3 — Find Your PC IP

```bash
ipconfig
# Look for IPv4 Address under WiFi adapter
# Example: 192.168.1.5
```

### Step 4 — Set Server IP in Flutter

Open `lib/utils/app_config.dart` and change:
```dart
static const String baseUrl = 'http://192.168.1.5:3000';
```

### Step 5 — Add Videos to Server

1. Copy your `.mp4` files into `backend/videos/`
2. Name them: `paracetamol_ta.mp4`, `paracetamol_en.mp4`, etc.
3. Insert URLs into database:

```sql
USE mediqr3;
INSERT INTO videos (medicine_id, language_code, video_url, file_name) VALUES
(1, 'ta', 'http://192.168.1.5:3000/videos/paracetamol_ta.mp4', 'paracetamol_ta.mp4'),
(1, 'en', 'http://192.168.1.5:3000/videos/paracetamol_en.mp4', 'paracetamol_en.mp4'),
(2, 'ta', 'http://192.168.1.5:3000/videos/amoxicillin_ta.mp4', 'amoxicillin_ta.mp4'),
(3, 'ta', 'http://192.168.1.5:3000/videos/metformin_ta.mp4', 'metformin_ta.mp4'),
(4, 'ta', 'http://192.168.1.5:3000/videos/ors_ta.mp4', 'ors_ta.mp4'),
(5, 'ta', 'http://192.168.1.5:3000/videos/iron_ta.mp4', 'iron_ta.mp4');
```

### Step 6 — Add App Icon

Copy your `logo.png` into `assets/images/logo.png` then manually replace icons:
```
android/app/src/main/res/mipmap-hdpi/ic_launcher.png
android/app/src/main/res/mipmap-mdpi/ic_launcher.png
android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
```

### Step 7 — Build APK

```bash
flutter pub get
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## Git Push Commands

### Push V3 for first time:
```bash
cd C:\Users\AJMAL\desktop\mediqr3
git init
git add .
git commit -m "MediQR V3 - User authentication, profiles, scan history"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/mediqr3.git
git push -u origin main
```

### Push V2 (if not pushed yet):
```bash
cd C:\Users\AJMAL\desktop\mediqr2
git init
git add .
git commit -m "MediQR V2 - Full backend, real QR scan, Chewie video, SQLite, Bluetooth"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/mediqr2.git
git push -u origin main
```

---

## API Endpoints

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | /api/auth/register | ❌ | Register user |
| POST | /api/auth/login | ❌ | Login |
| GET | /api/medicines | ✅ | Get all medicines |
| GET | /api/medicines/qr/:code | ✅ | Get by QR code |
| POST | /api/medicines/:id/videos | ✅ | Add video URL |
| POST | /api/scans | ✅ | Log scan |
| GET | /api/scans/history | ✅ | User scan history |
| GET | /api/users/profile | ✅ | Get profile |
| PUT | /api/users/profile | ✅ | Update profile |

---

## Medicines & QR Codes

| Medicine | QR Code |
|---|---|
| Paracetamol | `MED-PARA-001` |
| Amoxicillin | `MED-AMOX-001` |
| Metformin | `MED-METF-001` |
| ORS | `MED-ORS-001` |
| Iron+Folic Acid | `MED-IRON-001` |

---

## Default Credentials

- MySQL: `root` / `root`
- No default app users — register via the app

---

## MIT License

Copyright (c) 2025 Ajmal

Permission is hereby granted, free of charge, to any person obtaining a copy of this software to deal in the Software without restriction.
