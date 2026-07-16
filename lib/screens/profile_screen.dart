// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/local_db_service.dart';
import '../utils/app_config.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  final _localDb = LocalDbService();
  List<Map<String, dynamic>> _scanHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _localDb.getScanHistory();
    setState(() { _scanHistory = history; _loading = false; });
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Profile', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF2196F3)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white24,
                  child: Text(
                    user?.name.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.name ?? '', style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(user?.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.role == 'pharmacist' ? '💊 Pharmacist' : '🧑 Patient',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ])),
              ]),
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(children: [
              _statCard('Scans', _scanHistory.length.toString(), Icons.qr_code),
              const SizedBox(width: 12),
              _statCard('Language', _getLangName(user?.preferredLanguage ?? 'en'), Icons.language),
              const SizedBox(width: 12),
              _statCard('Phone', user?.phone ?? '-', Icons.phone),
            ]),
            const SizedBox(height: 24),

            // Settings section
            Text('Settings', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _settingsTile(Icons.language, 'Preferred Language', user?.preferredLanguage ?? 'en'),
            _settingsTile(Icons.notifications_outlined, 'Notifications', 'Enabled'),
            _settingsTile(Icons.info_outline, 'App Version', AppConfig.version),
            const SizedBox(height: 24),

            // Scan history
            Text('Recent Scans', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_loading)
              const CircularProgressIndicator()
            else if (_scanHistory.isEmpty)
              Text('No scans yet', style: TextStyle(color: Colors.grey[500]))
            else
              ...(_scanHistory.take(5).map((s) => _historyTile(s))),

            const SizedBox(height: 24),

            // Logout
            SizedBox(
              width: double.infinity, height: 50,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLangName(String code) {
    return AppConfig.languages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'native': code},
    )['native'] ?? code;
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(children: [
          Icon(icon, color: const Color(0xFF2196F3), size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _settingsTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF2196F3), size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
        Text(value, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      ]),
    );
  }

  Widget _historyTile(Map<String, dynamic> scan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.qr_code, color: Color(0xFF2196F3), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(scan['medicine_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Text(scan['scanned_at']?.toString().substring(0, 16) ?? '',
            style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ])),
      ]),
    );
  }
}
