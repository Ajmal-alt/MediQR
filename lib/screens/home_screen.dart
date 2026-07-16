// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/medicine_service.dart';
import '../models/medicine_model.dart';
import 'qr_scanner_screen.dart';
import 'my_videos_screen.dart';
import 'profile_screen.dart';
import 'transfer_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  final _medicineService = MedicineService();
  List<MedicineModel> _medicines = [];
  bool _loading = true;
  bool _serverOnline = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    try {
      final meds = await _medicineService.getAllMedicines();
      setState(() {
        _medicines = meds;
        _serverOnline = meds.isNotEmpty;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _HomeTab(),
          QRScannerScreen(),
          MyVideosScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2196F3).withOpacity(0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: 'Videos'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _auth = AuthService();
  final _medicineService = MedicineService();
  List<MedicineModel> _medicines = [];
  bool _loading = true;
  bool _serverOnline = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final meds = await _medicineService.getAllMedicines();
      setState(() { _medicines = meds; _serverOnline = meds.isNotEmpty; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2196F3),
                  child: Text(user?.name.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hello, ${user?.name ?? 'User'}! 👋',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(user?.role == 'pharmacist' ? 'Pharmacist' : 'Patient',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ])),
                Image.asset('assets/images/logo.png', height: 36),
              ]),
              const SizedBox(height: 20),

              // Status card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _serverOnline
                        ? [const Color(0xFF1B5E20), const Color(0xFF4CAF50)]
                        : [const Color(0xFF1A237E), const Color(0xFF2196F3)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Icon(_serverOnline ? Icons.cloud_done : Icons.cloud_off, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_serverOnline ? 'Server Connected' : 'Offline Mode',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${_medicines.length} medicines available',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ])),
                ]),
              ),
              const SizedBox(height: 20),

              // Quick actions
              Row(children: [
                Expanded(child: _actionCard(
                  icon: Icons.qr_code_scanner, label: 'Scan QR', color: const Color(0xFFFFA726),
                  onTap: () {},
                )),
                const SizedBox(width: 12),
                Expanded(child: _actionCard(
                  icon: Icons.wifi_tethering, label: 'Transfer', color: const Color(0xFF9C27B0),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferScreen())),
                )),
              ]),
              const SizedBox(height: 24),

              Text('Medicine Library', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_medicines.isEmpty)
                Center(child: Column(children: [
                  const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text('Cannot reach server', style: TextStyle(color: Colors.grey[500])),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ]))
              else
                ...(_medicines.map((m) => _medicineCard(m))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionCard({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _medicineCard(MedicineModel m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFF2196F3).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.medication_outlined, color: Color(0xFF2196F3)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          Text(m.category, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ])),
        const Icon(Icons.chevron_right, color: Colors.grey),
      ]),
    );
  }
}
