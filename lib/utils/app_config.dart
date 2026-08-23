// lib/utils/app_config.dart
class AppConfig {
  // ⚠️ Change this to your server IP before building
  static const String baseUrl = 'http://255.255.255.0:3000';
  static const String apiUrl = '$baseUrl/api';

  // App info
  static const String appName = 'MediQR';
  static const String version = '3.0.0';

  // Supported languages
  static const List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
    {'code': 'te', 'name': 'Telugu', 'native': 'తెలుగు'},
  ];

  // Medicine list
  static const List<String> medicines = [
    'Paracetamol',
    'Amoxicillin',
    'Metformin',
    'ORS',
    'Iron+Folic Acid',
  ];
}
