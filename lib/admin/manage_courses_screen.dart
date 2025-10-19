import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/course.dart';
import '../main.dart';

class ManageCoursesScreen extends ConsumerStatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  ConsumerState<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends ConsumerState<ManageCoursesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Courses'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data!.docs
              .map((doc) => Course.fromFirestore(doc))
              .toList();

          if (courses.isEmpty) {
            return const Center(child: Text('No courses yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              return _CourseItem(course: courses[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Course'),
      ),
    );
  }

  Future<void> _showCourseDialog(BuildContext context, [Course? course]) async {
    final titleController = TextEditingController(text: course?.title);
    final descController = TextEditingController(text: course?.description);
    final instructorController = TextEditingController(text: course?.instructor);
    final tagsController = TextEditingController(
      text: course?.tags.join(', '),
    );
    bool isPublished = course?.isPublished ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(course == null ? 'Add Course' : 'Edit Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: instructorController,
                  decoration: const InputDecoration(labelText: 'Instructor'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma-separated)',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Published'),
                  value: isPublished,
                  onChanged: (value) {
                    setState(() => isPublished = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveCourse(
                  course: course,
                  title: titleController.text,
                  description: descController.text,
                  instructor: instructorController.text,
                  tags: tagsController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  isPublished: isPublished,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCourse({
    Course? course,
    required String title,
    required String description,
    required String instructor,
    required List<String> tags,
    required bool isPublished,
  }) async {
    try {
      final now = DateTime.now();

      if (course == null) {
        // Create new course
        await FirebaseFirestore.instance.collection('courses').add({
          'title': title,
          'description': description,
          'instructor': instructor,
          'tags': tags,
          'isPublished': isPublished,
          'createdAt': Timestamp.fromDate(now),
          'enrolledCount': 0,
          'pdfUrls': [],
        });
      } else {
        // Update existing course
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(course.id)
            .update({
          'title': title,
          'description': description,
          'instructor': instructor,
          'tags': tags,
          'isPublished': isPublished,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _CourseItem extends ConsumerWidget {
  final Course course;

  const _CourseItem({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ExpansionTile(
        leading: course.thumbnailUrl != null
            ? Image.network(course.thumbnailUrl!, width: 60, height: 60, fit: BoxFit.cover)
            : const Icon(Icons.school, size: 40),
        title: Text(course.title),
        subtitle: Text(
          course.isPublished ? 'Published' : 'Draft',
          style: TextStyle(
            color: course.isPublished ? Colors.green : Colors.orange,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.description),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Edit'),
                      avatar: const Icon(Icons.edit, size: 16),
                      onPressed: () {
                        // TODO: Show edit dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit coming soon')),
                        );
                      },
                    ),
                    ActionChip(
                      label: const Text('Upload Thumbnail'),
                      avatar: const Icon(Icons.image, size: 16),
                      onPressed: () => _uploadThumbnail(context, ref),
                    ),
                    ActionChip(
                      label: const Text('Delete'),
                      avatar: const Icon(Icons.delete, size: 16),
                      onPressed: () => _deleteCourse(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadThumbnail(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading thumbnail...')),
        );
      }

      final storageService = ref.read(storageServiceProvider);
      final url = await storageService.uploadThumbnail(
        courseId: course.id,
        file: File(image.path),
        fileName: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await FirebaseFirestore.instance
          .collection('courses')
          .doc(course.id)
          .update({'thumbnailUrl': url});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thumbnail uploaded successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteCourse(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Course'),
        content: const Text('Are you sure you want to delete this course?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(course.id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
