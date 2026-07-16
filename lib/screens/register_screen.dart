// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utils/app_config.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _role = 'patient';
  String _language = 'en';
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _register() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final result = await AuthService().register(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: _role,
      preferredLanguage: _language,
    );
    setState(() => _loading = false);
    if (result['success']) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() => _error = result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Create Account', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join MediQR', style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Medicine guidance for everyone', style: GoogleFonts.poppins(
                color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 32),

              _buildLabel('Full Name'),
              _buildField(controller: _nameCtrl, hint: 'Your name', icon: Icons.person_outline),
              const SizedBox(height: 16),

              _buildLabel('Phone'),
              _buildField(controller: _phoneCtrl, hint: '+91 XXXXX XXXXX', icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone),
              const SizedBox(height: 16),

              _buildLabel('Email'),
              _buildField(controller: _emailCtrl, hint: 'your@email.com', icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),

              _buildLabel('Password'),
              _buildField(controller: _passCtrl, hint: '••••••••', icon: Icons.lock_outline,
                obscure: _obscure,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )),
              const SizedBox(height: 20),

              _buildLabel('Role'),
              Row(children: [
                _roleChip('patient', 'Patient', Icons.personal_injury_outlined),
                const SizedBox(width: 12),
                _roleChip('pharmacist', 'Pharmacist', Icons.medical_services_outlined),
              ]),
              const SizedBox(height: 20),

              _buildLabel('Preferred Language'),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: AppConfig.languages.map((lang) {
                  final selected = _language == lang['code'];
                  return GestureDetector(
                    onTap: () => setState(() => _language = lang['code']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF2196F3) : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: selected ? const Color(0xFF2196F3) : const Color(0xFF2A2A2A)),
                      ),
                      child: Text(lang['native']!,
                        style: TextStyle(color: selected ? Colors.white : Colors.grey, fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Create Account', style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String value, String label, IconData icon) {
    final selected = _role == value;
    return GestureDetector(
      onTap: () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2196F3).withOpacity(0.2) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF2196F3) : const Color(0xFF2A2A2A)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? const Color(0xFF2196F3) : Colors.grey, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
            color: selected ? const Color(0xFF2196F3) : Colors.grey,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          )),
        ]),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
