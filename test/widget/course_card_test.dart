import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harsh/widgets/course_card.dart';
import 'package:harsh/models/course.dart';

void main() {
  group('CourseCard Widget Tests', () {
    late Course testCourse;

    setUp(() {
      testCourse = Course(
        id: 'test-id',
        title: 'Test Course',
        description: 'This is a test course description',
        instructor: 'Test Instructor',
        createdAt: DateTime.now(),
        isPublished: true,
        enrolledCount: 42,
        tags: ['Flutter', 'Dart'],
      );
    });

    testWidgets('displays course title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(
              course: testCourse,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Course'), findsOneWidget);
    });

    testWidgets('displays course description', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(
              course: testCourse,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('This is a test course description'), findsOneWidget);
    });

    testWidgets('displays instructor name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(
              course: testCourse,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Instructor'), findsOneWidget);
    });

    testWidgets('displays enrolled count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(
              course: testCourse,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('displays course tags', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(
              course: testCourse,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(
              course: testCourse,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('displays placeholder icon when no thumbnail',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(
              course: testCourse,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('truncates long description', (WidgetTester tester) async {
      final longDescCourse = testCourse.copyWith(
        description: 'A' * 200, // Very long description
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CourseCard(
              course: longDescCourse,
              onTap: () {},
            ),
          ),
        ),
      );

      // Text should be truncated (maxLines: 2)
      final textWidget = tester.widget<Text>(
        find.text(longDescCourse.description),
      );
      expect(textWidget.maxLines, equals(2));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });
  });
}
