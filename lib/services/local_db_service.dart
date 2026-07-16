// lib/services/local_db_service.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medicine_model.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'mediqr3.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    // Cached medicines
    await db.execute('''
      CREATE TABLE cached_medicines (
        id INTEGER PRIMARY KEY,
        name TEXT,
        qr_code TEXT UNIQUE,
        description TEXT,
        instructions TEXT,
        video_urls TEXT,
        category TEXT,
        dosage TEXT,
        side_effects TEXT,
        cached_at TEXT
      )
    ''');

    // Offline video library
    await db.execute('''
      CREATE TABLE offline_videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicine_name TEXT,
        language TEXT,
        video_path TEXT,
        is_asset INTEGER DEFAULT 0,
        added_at TEXT
      )
    ''');

    // User scan history (local)
    await db.execute('''
      CREATE TABLE scan_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        qr_code TEXT,
        medicine_name TEXT,
        scanned_at TEXT
      )
    ''');

    // Preload offline asset videos
    await _seedOfflineVideos(db);
  }

  Future<void> _seedOfflineVideos(Database db) async {
    final videos = [
      {'medicine_name': 'MediQR Tutorial', 'language': 'Tamil', 'video_path': 'assets/videos/mediqr_intro_tam.mp4', 'is_asset': 1},
    ];
    for (final v in videos) {
      await db.insert('offline_videos', {
        ...v,
        'added_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Cache medicine from server
  Future<void> cacheMedicine(MedicineModel medicine) async {
    final db = await database;
    await db.insert('cached_medicines', {
      'id': medicine.id,
      'name': medicine.name,
      'qr_code': medicine.qrCode,
      'description': medicine.description,
      'instructions': jsonEncode(medicine.instructions),
      'video_urls': jsonEncode(medicine.videoUrls),
      'category': medicine.category,
      'dosage': medicine.dosage,
      'side_effects': medicine.sideEffects,
      'cached_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get medicine by QR from cache
  Future<MedicineModel?> getMedicineByQR(String qrCode) async {
    final db = await database;
    final rows = await db.query('cached_medicines', where: 'qr_code = ?', whereArgs: [qrCode]);
    if (rows.isEmpty) return null;
    return _rowToMedicine(rows.first);
  }

  // Get all cached medicines
  Future<List<MedicineModel>> getAllCachedMedicines() async {
    final db = await database;
    final rows = await db.query('cached_medicines');
    return rows.map(_rowToMedicine).toList();
  }

  MedicineModel _rowToMedicine(Map<String, dynamic> row) {
    return MedicineModel(
      id: row['id'],
      name: row['name'],
      qrCode: row['qr_code'],
      description: row['description'],
      instructions: Map<String, String>.from(jsonDecode(row['instructions'])),
      videoUrls: Map<String, String>.from(jsonDecode(row['video_urls'])),
      category: row['category'],
      dosage: row['dosage'],
      sideEffects: row['side_effects'],
    );
  }

  // Get offline videos
  Future<List<Map<String, dynamic>>> getOfflineVideos() async {
    final db = await database;
    return await db.query('offline_videos', orderBy: 'added_at DESC');
  }

  // Add video to offline library
  Future<void> addOfflineVideo(String medicineName, String language, String path) async {
    final db = await database;
    await db.insert('offline_videos', {
      'medicine_name': medicineName,
      'language': language,
      'video_path': path,
      'is_asset': 0,
      'added_at': DateTime.now().toIso8601String(),
    });
  }

  // Log scan locally
  Future<void> logScan(String qrCode, String medicineName) async {
    final db = await database;
    await db.insert('scan_history', {
      'qr_code': qrCode,
      'medicine_name': medicineName,
      'scanned_at': DateTime.now().toIso8601String(),
    });
  }

  // Get scan history
  Future<List<Map<String, dynamic>>> getScanHistory() async {
    final db = await database;
    return await db.query('scan_history', orderBy: 'scanned_at DESC', limit: 50);
  }
}
