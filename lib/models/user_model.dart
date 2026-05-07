import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// Maps to the `users` collection in Firestore.
class AppUser {
  const AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.sectorId,
  });

  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final String? sectorId;

  AppUser copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? sectorId,
  }) {
    return AppUser(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      sectorId: sectorId ?? this.sectorId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role.value,
      if (sectorId != null) 'sectorId': sectorId,
    };
  }

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      userId: data['userId'] as String? ?? id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      sectorId: data['sectorId'] as String?,
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser.fromFirestore(d, doc.id);
  }
}
