import 'package:cloud_firestore/cloud_firestore.dart';

class Lecture {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final int orderIndex;
  final DateTime createdAt;
  final bool isPublished;
  final LectureType type;

  Lecture({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.videoUrl,
    this.thumbnailUrl,
    this.durationSeconds = 0,
    required this.orderIndex,
    required this.createdAt,
    this.isPublished = false,
    required this.type,
  });

  factory Lecture.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lecture(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      videoUrl: data['videoUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      durationSeconds: data['durationSeconds'] ?? 0,
      orderIndex: data['orderIndex'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isPublished: data['isPublished'] ?? false,
      type: LectureType.values.firstWhere(
        (e) => e.toString() == 'LectureType.${data['type']}',
        orElse: () => LectureType.recorded,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'orderIndex': orderIndex,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublished': isPublished,
      'type': type.toString().split('.').last,
    };
  }

  Lecture copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    int? durationSeconds,
    int? orderIndex,
    DateTime? createdAt,
    bool? isPublished,
    LectureType? type,
  }) {
    return Lecture(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      isPublished: isPublished ?? this.isPublished,
      type: type ?? this.type,
    );
  }
}

enum LectureType {
  recorded,
  live,
}

class LiveSession {
  final String id;
  final String courseId;
  final String title;
  final DateTime scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String channelName;
  final bool isActive;
  final String? recordingUrl;

  LiveSession({
    required this.id,
    required this.courseId,
    required this.title,
    required this.scheduledAt,
    this.startedAt,
    this.endedAt,
    required this.channelName,
    this.isActive = false,
    this.recordingUrl,
  });

  factory LiveSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LiveSession(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      scheduledAt: (data['scheduledAt'] as Timestamp).toDate(),
      startedAt: data['startedAt'] != null 
          ? (data['startedAt'] as Timestamp).toDate() 
          : null,
      endedAt: data['endedAt'] != null 
          ? (data['endedAt'] as Timestamp).toDate() 
          : null,
      channelName: data['channelName'] ?? '',
      isActive: data['isActive'] ?? false,
      recordingUrl: data['recordingUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'title': title,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'channelName': channelName,
      'isActive': isActive,
      'recordingUrl': recordingUrl,
    };
  }
}
