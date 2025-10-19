import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final List<String> enrolledCourses;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    this.enrolledCourses = const [],
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.student,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      enrolledCourses: List<String>.from(data['enrolledCourses'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'enrolledCourses': enrolledCourses,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
    List<String>? enrolledCourses,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      enrolledCourses: enrolledCourses ?? this.enrolledCourses,
    );
  }
}

enum UserRole {
  student,
  admin,
}
