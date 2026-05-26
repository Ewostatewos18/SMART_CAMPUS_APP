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
    this.department,
    this.studentId,
    this.profileImageUrl,
    this.fcmToken,
    this.createdAt,
  });

  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final String? sectorId;
  final String? department;
  final String? studentId;
  final String? profileImageUrl;
  final String? fcmToken;
  final DateTime? createdAt;

  AppUser copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? sectorId,
    String? department,
    String? studentId,
    String? profileImageUrl,
    String? fcmToken,
  }) {
    return AppUser(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      sectorId: sectorId ?? this.sectorId,
      department: department ?? this.department,
      studentId: studentId ?? this.studentId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': role.value,
      if (sectorId != null) 'sectorId': sectorId,
      if (department != null) 'department': department,
      if (studentId != null) 'studentId': studentId,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    final rawCreated = data['createdAt'];
    DateTime? created;
    if (rawCreated is Timestamp) created = rawCreated.toDate();

    return AppUser(
      userId: data['userId'] as String? ?? id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      sectorId: data['sectorId'] as String?,
      department: data['department'] as String?,
      studentId: data['studentId'] as String?,
      profileImageUrl: data['profileImageUrl'] as String?,
      fcmToken: data['fcmToken'] as String?,
      createdAt: created,
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUser.fromFirestore(doc.data() ?? {}, doc.id);
  }
}
