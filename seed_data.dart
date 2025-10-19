import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Seed script to populate Firestore with sample data
/// 
/// This creates:
/// - 1 sample course
/// - 1 sample lecture
/// - 1 sample PDF URL
/// 
/// Usage:
/// 1. Ensure Firebase is configured
/// 2. Run: dart run seed_data.dart

Future<void> main() async {
  print('🌱 Starting seed script...\n');

  // Initialize Firebase
  // Note: You may need to provide Firebase options manually
  // or ensure flutterfire configure has been run
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized\n');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    print('Make sure you have run: flutterfire configure');
    return;
  }

  final firestore = FirebaseFirestore.instance;

  try {
    // Create sample course
    print('📚 Creating sample course...');
    final courseRef = await firestore.collection('courses').add({
      'title': 'Introduction to Flutter Development',
      'description': 'Learn Flutter from scratch and build beautiful cross-platform applications. '
          'This comprehensive course covers everything from basic widgets to advanced state management.',
      'instructor': 'Dr. Sarah Johnson',
      'thumbnailUrl': 'https://via.placeholder.com/800x450/4285F4/FFFFFF?text=Flutter+Course',
      'createdAt': FieldValue.serverTimestamp(),
      'isPublished': true,
      'enrolledCount': 127,
      'tags': ['Flutter', 'Dart', 'Mobile Development', 'Cross-Platform'],
      'pdfUrls': [
        'https://flutter.dev/assets/flutter-logo-sharing.png',
        // Add real PDF URLs here after uploading to Firebase Storage
      ],
    });

    final courseId = courseRef.id;
    print('✅ Course created with ID: $courseId\n');

    // Create sample lecture
    print('🎥 Creating sample lecture...');
    await firestore.collection('lectures').add({
      'courseId': courseId,
      'title': 'Getting Started with Flutter',
      'description': 'In this lecture, we will set up Flutter development environment '
          'and create our first Flutter application.',
      'videoUrl': 'https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      // Note: This is a sample video URL. Replace with actual lecture video from Firebase Storage
      'thumbnailUrl': 'https://via.placeholder.com/480x270/34A853/FFFFFF?text=Lecture+1',
      'durationSeconds': 1800, // 30 minutes
      'orderIndex': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'isPublished': true,
      'type': 'recorded',
    });
    print('✅ Lecture created\n');

    // Create sample live session
    print('📺 Creating sample live session...');
    await firestore.collection('liveSessions').add({
      'courseId': courseId,
      'title': 'Live Q&A: Flutter State Management',
      'scheduledAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 2, hours: 14)),
      ),
      'channelName': 'live_${DateTime.now().millisecondsSinceEpoch}',
      'isActive': false,
    });
    print('✅ Live session scheduled\n');

    // Create sample analytics entries
    print('📊 Creating sample analytics...');
    await firestore.collection('analytics').add({
      'eventName': 'lecture_played',
      'data': {
        'userId': 'sample_user_1',
        'courseId': courseId,
        'lectureId': 'sample_lecture_1',
      },
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('✅ Analytics entry created\n');

    // Print summary
    print('=' * 50);
    print('🎉 Seed data created successfully!');
    print('=' * 50);
    print('');
    print('Summary:');
    print('  ✓ 1 Course: "Introduction to Flutter Development"');
    print('  ✓ 1 Lecture: "Getting Started with Flutter"');
    print('  ✓ 1 Live Session: Scheduled for 2 days from now');
    print('  ✓ 1 Analytics entry');
    print('');
    print('Course ID: $courseId');
    print('');
    print('Next steps:');
    print('  1. Create an admin user in Firebase Auth');
    print('  2. Update the user\'s role to "admin" in Firestore');
    print('  3. Upload real PDFs and videos to Firebase Storage');
    print('  4. Update the URLs in the course document');
    print('');
  } catch (e) {
    print('❌ Error seeding data: $e');
    print('');
    print('Troubleshooting:');
    print('  - Ensure Firestore is enabled in Firebase Console');
    print('  - Check that Firebase rules allow writes');
    print('  - Verify internet connection');
  }
}
