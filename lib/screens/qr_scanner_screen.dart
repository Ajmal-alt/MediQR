// lib/screens/qr_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/medicine_service.dart';
import '../services/local_db_service.dart';
import 'medicine_detail_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});
  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final _controller = MobileScannerController();
  final _medicineService = MedicineService();
  final _localDb = LocalDbService();
  bool _scanning = true;
  bool _loading = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_scanning || _loading) return;
    final barcode = capture.barcodes.first;
    final qrCode = barcode.rawValue;
    if (qrCode == null) return;

    setState(() { _scanning = false; _loading = true; });
    _controller.stop();

    final medicine = await _medicineService.getMedicineByQR(qrCode);
    await _localDb.logScan(qrCode, medicine?.name ?? 'Unknown');

    setState(() => _loading = false);

    if (!mounted) return;
    if (medicine != null) {
      await Navigator.push(context,
        MaterialPageRoute(builder: (_) => MedicineDetailScreen(medicine: medicine)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine not found for this QR code'), backgroundColor: Colors.red),
      );
    }

    setState(() => _scanning = true);
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: Container(),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Scan QR Code', style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Point camera at medicine QR code',
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ),

          // Loading
          if (_loading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),

          // Bottom controls
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _controlBtn(Icons.flash_off, () => _controller.toggleTorch()),
              const SizedBox(width: 20),
              _controlBtn(Icons.flip_camera_android, () => _controller.switchCamera()),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final cutoutSize = size.width * 0.7;
    final left = (size.width - cutoutSize) / 2;
    final top = (size.height - cutoutSize) / 2;
    final rect = Rect.fromLTWH(left, top, cutoutSize, cutoutSize);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
      ),
      paint,
    );

    // Corner borders
    final borderPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const len = 24.0;
    canvas.drawLine(Offset(left, top), Offset(left + len, top), borderPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + len), borderPaint);
    canvas.drawLine(Offset(left + cutoutSize, top), Offset(left + cutoutSize - len, top), borderPaint);
    canvas.drawLine(Offset(left + cutoutSize, top), Offset(left + cutoutSize, top + len), borderPaint);
    canvas.drawLine(Offset(left, top + cutoutSize), Offset(left + len, top + cutoutSize), borderPaint);
    canvas.drawLine(Offset(left, top + cutoutSize), Offset(left, top + cutoutSize - len), borderPaint);
    canvas.drawLine(Offset(left + cutoutSize, top + cutoutSize), Offset(left + cutoutSize - len, top + cutoutSize), borderPaint);
    canvas.drawLine(Offset(left + cutoutSize, top + cutoutSize), Offset(left + cutoutSize, top + cutoutSize - len), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
