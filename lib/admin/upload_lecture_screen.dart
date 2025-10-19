import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../main.dart';
import '../models/course.dart';
import '../models/lecture.dart';

class UploadLectureScreen extends ConsumerStatefulWidget {
  final String courseId;

  const UploadLectureScreen({
    super.key,
    required this.courseId,
  });

  @override
  ConsumerState<UploadLectureScreen> createState() =>
      _UploadLectureScreenState();
}

class _UploadLectureScreenState extends ConsumerState<UploadLectureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  File? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _isPublished = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Lecture'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final course = Course.fromFirestore(snapshot.data!);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Course info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Instructor: ${course.instructor}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lecture details
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Lecture Title',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (seconds)',
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter duration';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Published'),
                    subtitle: const Text('Make this lecture visible to students'),
                    value: _isPublished,
                    onChanged: (value) {
                      setState(() => _isPublished = value);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Video file picker
                  if (_selectedFile == null)
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickFile,
                      icon: const Icon(Icons.video_library),
                      label: const Text('Select Video File (MP4)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(24),
                      ),
                    )
                  else
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.video_file, size: 40),
                        title: Text(_selectedFile!.path.split('/').last),
                        subtitle: Text(_formatFileSize(_selectedFile!.lengthSync())),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _isUploading
                              ? null
                              : () => setState(() => _selectedFile = null),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Upload button
                  if (_selectedFile != null && !_isUploading)
                    ElevatedButton.icon(
                      onPressed: _uploadLecture,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Lecture'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),

                  // Upload progress
                  if (_isUploading) ...[
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Existing lectures
                  _buildExistingLectures(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExistingLectures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Existing Lectures',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lectures')
              .where('courseId', isEqualTo: widget.courseId)
              .orderBy('orderIndex')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final lectures = snapshot.data!.docs
                .map((doc) => Lecture.fromFirestore(doc))
                .toList();

            if (lectures.isEmpty) {
              return const Center(child: Text('No lectures uploaded yet.'));
            }

            return Column(
              children: lectures.map((lecture) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(lecture.title),
                    subtitle: Text(
                      '${_formatDuration(lecture.durationSeconds)} • ${lecture.isPublished ? "Published" : "Draft"}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteLecture(lecture),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'avi'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _uploadLecture() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final storageService = ref.read(storageServiceProvider);
      final fileName = _selectedFile!.path.split('/').last;

      // Upload video
      final videoUrl = await storageService.uploadVideo(
        courseId: widget.courseId,
        file: _selectedFile!,
        fileName: fileName,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      // Get next order index
      final lecturesSnapshot = await FirebaseFirestore.instance
          .collection('lectures')
          .where('courseId', isEqualTo: widget.courseId)
          .get();
      final nextOrderIndex = lecturesSnapshot.docs.length;

      // Create lecture document
      final lecture = Lecture(
        id: '',
        courseId: widget.courseId,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        videoUrl: videoUrl,
        durationSeconds: int.parse(_durationController.text),
        orderIndex: nextOrderIndex,
        createdAt: DateTime.now(),
        isPublished: _isPublished,
        type: LectureType.recorded,
      );

      await FirebaseFirestore.instance
          .collection('lectures')
          .add(lecture.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lecture uploaded successfully')),
        );

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _durationController.clear();
        setState(() {
          _selectedFile = null;
          _isPublished = false;
        });
      }

      // Send notification
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.notifyNewContent(
        courseId: widget.courseId,
        contentType: 'lecture',
        title: _titleController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deleteLecture(Lecture lecture) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lecture'),
        content: const Text('Are you sure you want to delete this lecture?'),
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
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('lectures')
          .doc(lecture.id)
          .delete();

      // Delete video from Storage
      if (lecture.videoUrl != null) {
        final storageService = ref.read(storageServiceProvider);
        await storageService.deleteFile(lecture.videoUrl!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lecture deleted successfully')),
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}
