import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../main.dart';
import '../models/course.dart';

class UploadPDFScreen extends ConsumerStatefulWidget {
  final String courseId;

  const UploadPDFScreen({
    super.key,
    required this.courseId,
  });

  @override
  ConsumerState<UploadPDFScreen> createState() => _UploadPDFScreenState();
}

class _UploadPDFScreenState extends ConsumerState<UploadPDFScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload PDF'),
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

                // File picker
                if (_selectedFile == null)
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickFile,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Select PDF File'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(24),
                    ),
                  )
                else
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf, size: 40),
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
                    onPressed: _uploadPDF,
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload PDF'),
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

                // Existing PDFs
                Text(
                  'Uploaded PDFs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                if (course.pdfUrls.isEmpty)
                  const Center(child: Text('No PDFs uploaded yet.'))
                else
                  ...course.pdfUrls.map((url) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.picture_as_pdf),
                          title: Text(url.split('/').last.split('?').first),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePDF(url, course),
                          ),
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
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

  Future<void> _uploadPDF() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final storageService = ref.read(storageServiceProvider);
      final fileName = _selectedFile!.path.split('/').last;

      final url = await storageService.uploadPDF(
        courseId: widget.courseId,
        file: _selectedFile!,
        fileName: fileName,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
        },
      );

      // Add PDF URL to course
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .update({
        'pdfUrls': FieldValue.arrayUnion([url]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF uploaded successfully')),
        );
        setState(() => _selectedFile = null);
      }

      // Send notification to enrolled students
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.notifyNewContent(
        courseId: widget.courseId,
        contentType: 'pdf',
        title: fileName,
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

  Future<void> _deletePDF(String url, Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF'),
        content: const Text('Are you sure you want to delete this PDF?'),
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
      // Remove from Firestore
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .update({
        'pdfUrls': FieldValue.arrayRemove([url]),
      });

      // Delete from Storage
      final storageService = ref.read(storageServiceProvider);
      await storageService.deleteFile(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF deleted successfully')),
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
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
