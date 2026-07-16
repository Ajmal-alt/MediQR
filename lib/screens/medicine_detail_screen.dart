// lib/screens/medicine_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/medicine_model.dart';
import '../services/auth_service.dart';

class MedicineDetailScreen extends StatefulWidget {
  final MedicineModel medicine;
  const MedicineDetailScreen({super.key, required this.medicine});
  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String _selectedLang = 'en';
  bool _videoLoading = false;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    _selectedLang = user?.preferredLanguage ?? 'en';
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final videoUrl = widget.medicine.videoUrls[_selectedLang] ??
        widget.medicine.videoUrls.values.firstOrNull;
    if (videoUrl == null) return;

    setState(() { _videoLoading = true; _videoError = false; });

    try {
      _videoController?.dispose();
      _chewieController?.dispose();

      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF2196F3),
          handleColor: const Color(0xFF2196F3),
        ),
      );

      setState(() {
        _videoController = controller;
        _videoLoading = false;
      });
    } catch (e) {
      setState(() { _videoLoading = false; _videoError = true; });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.medicine;
    final instruction = m.instructions[_selectedLang] ?? m.instructions.values.firstOrNull ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(m.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video player
            Container(
              color: Colors.black,
              height: 220,
              child: _videoLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _videoError
                      ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.error_outline, color: Colors.white54, size: 40),
                          SizedBox(height: 8),
                          Text('Video unavailable', style: TextStyle(color: Colors.white54)),
                        ]))
                      : _chewieController != null
                          ? Chewie(controller: _chewieController!)
                          : const Center(child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 60)),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language selector
                  Text('Select Language', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: m.videoUrls.keys.map((lang) {
                        final selected = _selectedLang == lang;
                        return GestureDetector(
                          onTap: () { setState(() => _selectedLang = lang); _loadVideo(); },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFF2196F3) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? const Color(0xFF2196F3) : Colors.grey.shade300),
                            ),
                            child: Text(lang.toUpperCase(),
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w600, fontSize: 12,
                              )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Medicine info
                  _infoCard('Instructions', instruction, Icons.info_outline),
                  const SizedBox(height: 12),
                  _infoCard('Dosage', m.dosage, Icons.medication_outlined),
                  const SizedBox(height: 12),
                  _infoCard('Side Effects', m.sideEffects, Icons.warning_amber_outlined),
                  const SizedBox(height: 12),
                  _infoCard('Description', m.description, Icons.description_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String content, IconData icon) {
    if (content.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFF2196F3), size: 20),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text(content, style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.5)),
        ])),
      ]),
    );
  }
}
