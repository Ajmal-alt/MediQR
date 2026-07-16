// lib/screens/my_videos_screen.dart
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/local_db_service.dart';

class MyVideosScreen extends StatefulWidget {
  const MyVideosScreen({super.key});
  @override
  State<MyVideosScreen> createState() => _MyVideosScreenState();
}

class _MyVideosScreenState extends State<MyVideosScreen> with SingleTickerProviderStateMixin {
  final _localDb = LocalDbService();
  List<Map<String, dynamic>> _offlineVideos = [];
  bool _loading = true;
  late TabController _tabController;

  // Preloaded tutorial/intro videos
  final List<Map<String, dynamic>> _tutorialVideos = [
    {
      'title': 'MediQR Introduction',
      'language': 'Tamil',
      'path': 'assets/videos/mediqr_intro_tam.mp4',
      'is_asset': true,
      'description': 'How to use MediQR app',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final videos = await _localDb.getOfflineVideos();
    setState(() { _offlineVideos = videos; _loading = false; });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text('My Videos', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2196F3),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF2196F3),
            tabs: const [Tab(text: 'Tutorial Videos'), Tab(text: 'Downloaded')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tutorial videos (preinstalled)
                _tutorialVideos.isEmpty
                    ? _emptyState('No tutorial videos', 'Tutorial videos will appear here')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tutorialVideos.length,
                        itemBuilder: (_, i) => _videoCard(_tutorialVideos[i], isAsset: true),
                      ),

                // Downloaded/cached videos
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _offlineVideos.isEmpty
                        ? _emptyState('No downloaded videos', 'Scan a QR while online to cache videos\nor receive via Bluetooth transfer')
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _offlineVideos.length,
                            itemBuilder: (_, i) => _videoCard(_offlineVideos[i]),
                          ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoCard(Map<String, dynamic> video, {bool isAsset = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => _VideoPlayerScreen(video: video, isAsset: isAsset),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.play_circle_filled, color: Color(0xFF2196F3), size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(video['title'] ?? video['medicine_name'] ?? 'Video',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            Text(video['language'] ?? '',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            if (video['description'] != null)
              Text(video['description'], style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isAsset
                  ? Colors.green.withOpacity(0.1)
                  : const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isAsset ? 'Built-in' : 'Cached',
              style: TextStyle(
                color: isAsset ? Colors.green : const Color(0xFF2196F3),
                fontSize: 10, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      ]),
    );
  }
}

class _VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> video;
  final bool isAsset;
  const _VideoPlayerScreen({required this.video, required this.isAsset});
  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final path = widget.video['path'] ?? widget.video['video_path'] ?? '';
      final controller = widget.isAsset
          ? VideoPlayerController.asset(path)
          : VideoPlayerController.networkUrl(Uri.parse(path));
      await controller.initialize();
      _chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFF2196F3),
          handleColor: const Color(0xFF2196F3),
        ),
      );
      setState(() { _controller = controller; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = true; });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _chewie?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.video['title'] ?? widget.video['medicine_name'] ?? 'Video',
          style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : _error
                ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.error_outline, color: Colors.white54, size: 48),
                    SizedBox(height: 12),
                    Text('Could not load video', style: TextStyle(color: Colors.white54)),
                  ])
                : _chewie != null
                    ? Chewie(controller: _chewie!)
                    : const SizedBox.shrink(),
      ),
    );
  }
}
