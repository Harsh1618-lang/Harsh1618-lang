import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String instructor;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublished;
  final List<String> pdfUrls;
  final int enrolledCount;
  final List<String> tags;

  Course({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.instructor,
    required this.createdAt,
    this.updatedAt,
    this.isPublished = false,
    this.pdfUrls = const [],
    this.enrolledCount = 0,
    this.tags = const [],
  });

  factory Course.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      instructor: data['instructor'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      isPublished: data['isPublished'] ?? false,
      pdfUrls: List<String>.from(data['pdfUrls'] ?? []),
      enrolledCount: data['enrolledCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'instructor': instructor,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isPublished': isPublished,
      'pdfUrls': pdfUrls,
      'enrolledCount': enrolledCount,
      'tags': tags,
    };
  }

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? instructor,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
    List<String>? pdfUrls,
    int? enrolledCount,
    List<String>? tags,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      instructor: instructor ?? this.instructor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
      pdfUrls: pdfUrls ?? this.pdfUrls,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      tags: tags ?? this.tags,
    );
  }
}
