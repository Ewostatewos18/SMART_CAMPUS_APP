import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_status.dart';
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
    this.year,
    this.section,
    this.phone,
    this.position,
    this.officeInfo,
    this.profileImageUrl,
    this.fcmToken,
    this.isActive = true,
    this.accountStatus = AccountStatus.approved,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final String? sectorId;
  final String? department;
  final String? studentId;
  final String? year;
  final String? section;
  final String? phone;
  final String? position;
  final String? officeInfo;
  final String? profileImageUrl;
  final String? fcmToken;
  final bool isActive;
  final AccountStatus accountStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName => name;

  bool get canSignIn =>
      isActive && accountStatus == AccountStatus.approved;

  AppUser copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? sectorId,
    String? department,
    String? studentId,
    String? year,
    String? section,
    String? phone,
    String? position,
    String? officeInfo,
    String? profileImageUrl,
    String? fcmToken,
    bool? isActive,
    AccountStatus? accountStatus,
    DateTime? updatedAt,
  }) {
    return AppUser(
      userId: userId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      sectorId: sectorId ?? this.sectorId,
      department: department ?? this.department,
      studentId: studentId ?? this.studentId,
      year: year ?? this.year,
      section: section ?? this.section,
      phone: phone ?? this.phone,
      position: position ?? this.position,
      officeInfo: officeInfo ?? this.officeInfo,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      isActive: isActive ?? this.isActive,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'fullName': name,
      'email': email,
      'role': role.value,
      'isActive': isActive,
      'accountStatus': accountStatus.value,
      if (sectorId != null) 'sectorId': sectorId,
      if (department != null) 'department': department,
      if (studentId != null) 'studentId': studentId,
      if (year != null) 'year': year,
      if (section != null) 'section': section,
      if (phone != null) 'phone': phone,
      if (position != null) 'position': position,
      if (officeInfo != null) 'officeInfo': officeInfo,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (profileImageUrl != null) 'photoUrl': profileImageUrl,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseTs(Object? raw) {
      if (raw is Timestamp) return raw.toDate();
      return null;
    }

    return AppUser(
      userId: data['userId'] as String? ?? id,
      name: data['fullName'] as String? ?? data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      sectorId: data['sectorId'] as String?,
      department: data['department'] as String?,
      studentId: data['studentId'] as String?,
      year: data['year'] as String?,
      section: data['section'] as String?,
      phone: data['phone'] as String?,
      position: data['position'] as String?,
      officeInfo: data['officeInfo'] as String?,
      profileImageUrl:
          data['photoUrl'] as String? ?? data['profileImageUrl'] as String?,
      fcmToken: data['fcmToken'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      accountStatus: AccountStatus.fromString(data['accountStatus'] as String?),
      createdAt: parseTs(data['createdAt']),
      updatedAt: parseTs(data['updatedAt']),
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUser.fromFirestore(doc.data() ?? {}, doc.id);
  }
}
