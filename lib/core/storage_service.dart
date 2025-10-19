import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload PDF to Firebase Storage
  Future<String> uploadPDF({
    required String courseId,
    required File file,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child('courses/$courseId/pdfs/$fileName');
      final uploadTask = ref.putFile(file);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      // Log analytics
      await _logAnalytics('pdf_uploaded', {
        'courseId': courseId,
        'fileName': fileName,
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload PDF: $e');
    }
  }

  // Upload video lecture to Firebase Storage
  Future<String> uploadVideo({
    required String courseId,
    required File file,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child('courses/$courseId/videos/$fileName');
      
      // Set metadata for video
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {'courseId': courseId},
      );

      final uploadTask = ref.putFile(file, metadata);

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      // Log analytics
      await _logAnalytics('video_uploaded', {
        'courseId': courseId,
        'fileName': fileName,
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  // Upload thumbnail image
  Future<String> uploadThumbnail({
    required String courseId,
    required File file,
    required String fileName,
  }) async {
    try {
      final ref = _storage.ref().child('courses/$courseId/thumbnails/$fileName');
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      await ref.putFile(file, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload thumbnail: $e');
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Download file to local storage
  Future<File> downloadFile({
    required String url,
    required String localPath,
    Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.refFromURL(url);
      final file = File(localPath);

      final downloadTask = ref.writeToFile(file);

      // Listen to download progress
      downloadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      await downloadTask;

      // Log analytics
      await _logAnalytics('file_downloaded', {
        'url': url,
        'fileName': path.basename(localPath),
      });

      return file;
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  // Get file metadata
  Future<FullMetadata> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('Failed to get file metadata: $e');
    }
  }

  // Log analytics event to Firestore
  Future<void> _logAnalytics(String eventName, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('analytics').add({
        'eventName': eventName,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail analytics logging
      print('Analytics logging failed: $e');
    }
  }

  // Log lecture play event
  Future<void> logLecturePlay({
    required String userId,
    required String courseId,
    required String lectureId,
  }) async {
    await _logAnalytics('lecture_played', {
      'userId': userId,
      'courseId': courseId,
      'lectureId': lectureId,
    });
  }

  // Log PDF view event
  Future<void> logPDFView({
    required String userId,
    required String courseId,
    required String pdfUrl,
  }) async {
    await _logAnalytics('pdf_viewed', {
      'userId': userId,
      'courseId': courseId,
      'pdfUrl': pdfUrl,
    });
  }
}
