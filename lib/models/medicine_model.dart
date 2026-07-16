// lib/models/medicine_model.dart
class MedicineModel {
  final int? id;
  final String name;
  final String qrCode;
  final String description;
  final Map<String, String> instructions; // language -> instruction
  final Map<String, String> videoUrls;    // language -> video URL
  final String category;
  final String dosage;
  final String sideEffects;

  MedicineModel({
    this.id,
    required this.name,
    required this.qrCode,
    required this.description,
    required this.instructions,
    required this.videoUrls,
    required this.category,
    required this.dosage,
    required this.sideEffects,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id'],
      name: json['name'],
      qrCode: json['qr_code'],
      description: json['description'] ?? '',
      instructions: Map<String, String>.from(json['instructions'] ?? {}),
      videoUrls: Map<String, String>.from(json['video_urls'] ?? {}),
      category: json['category'] ?? 'General',
      dosage: json['dosage'] ?? '',
      sideEffects: json['side_effects'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'qr_code': qrCode,
      'description': description,
      'instructions': instructions,
      'video_urls': videoUrls,
      'category': category,
      'dosage': dosage,
      'side_effects': sideEffects,
    };
  }
}
