// lib/models/user_model.dart
class UserModel {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String role; // 'patient' or 'pharmacist'
  final String preferredLanguage;
  final String? profileImage;
  final DateTime? createdAt;
  final List<String>? scannedMedicines;

  UserModel({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.preferredLanguage,
    this.profileImage,
    this.createdAt,
    this.scannedMedicines,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      role: json['role'],
      preferredLanguage: json['preferred_language'] ?? 'en',
      profileImage: json['profile_image'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      scannedMedicines: json['scanned_medicines'] != null
          ? List<String>.from(json['scanned_medicines'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'preferred_language': preferredLanguage,
      'profile_image': profileImage,
    };
  }
}
