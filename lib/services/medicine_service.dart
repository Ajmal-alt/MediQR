// lib/services/medicine_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medicine_model.dart';
import '../utils/app_config.dart';
import 'auth_service.dart';
import 'local_db_service.dart';

class MedicineService {
  static final MedicineService _instance = MedicineService._internal();
  factory MedicineService() => _instance;
  MedicineService._internal();

  final _auth = AuthService();
  final _localDb = LocalDbService();

  // Fetch medicine by QR code
  Future<MedicineModel?> getMedicineByQR(String qrCode) async {
    try {
      final token = await _auth.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/medicines/qr/$qrCode'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final medicine = MedicineModel.fromJson(data['medicine']);
        // Cache locally
        await _localDb.cacheMedicine(medicine);
        // Log scan
        await _logScan(qrCode, medicine.id);
        return medicine;
      }
    } catch (e) {
      // Try offline cache
      return await _localDb.getMedicineByQR(qrCode);
    }
    return null;
  }

  // Get all medicines
  Future<List<MedicineModel>> getAllMedicines() async {
    try {
      final token = await _auth.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/medicines'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List medicines = data['medicines'];
        return medicines.map((m) => MedicineModel.fromJson(m)).toList();
      }
    } catch (e) {
      return await _localDb.getAllCachedMedicines();
    }
    return [];
  }

  // Log scan to server
  Future<void> _logScan(String qrCode, int? medicineId) async {
    try {
      final token = await _auth.getToken();
      await http.post(
        Uri.parse('${AppConfig.apiUrl}/scans'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'qr_code': qrCode,
          'medicine_id': medicineId,
        }),
      );
    } catch (_) {}
  }

  // Get user scan history
  Future<List<Map<String, dynamic>>> getScanHistory() async {
    try {
      final token = await _auth.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/scans/history'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['history']);
      }
    } catch (_) {}
    return [];
  }
}
