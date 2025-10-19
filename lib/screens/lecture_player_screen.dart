import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/lecture.dart';
import '../main.dart';

class LecturePlayerScreen extends ConsumerStatefulWidget {
  final String lectureId;

  const LecturePlayerScreen({
    super.key,
    required this.lectureId,
  });

  @override
  ConsumerState<LecturePlayerScreen> createState() =>
      _LecturePlayerScreenState();
}

class _LecturePlayerScreenState extends ConsumerState<LecturePlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLecture();
  }

  Future<void> _loadLecture() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('lectures')
          .doc(widget.lectureId)
          .get();

      if (!doc.exists) {
        setState(() {
          _isLoading = false;
          _error = 'Lecture not found';
        });
        return;
      }

      final lecture = Lecture.fromFirestore(doc);

      if (lecture.videoUrl == null) {
        setState(() {
          _isLoading = false;
          _error = 'Video not available';
        });
        return;
      }

      await _initializeVideo(lecture.videoUrl!);

      // Log analytics
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      if (user != null) {
        ref.read(storageServiceProvider).logLecturePlay(
              userId: user.uid,
              courseId: lecture.courseId,
              lectureId: lecture.id,
            );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load lecture: $e';
      });
    }
  }

  Future<void> _initializeVideo(String videoUrl) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoController!.value.aspectRatio,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadLecture();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lectures')
          .doc(widget.lectureId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final lecture = Lecture.fromFirestore(snapshot.data!);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video player
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: Chewie(controller: _chewieController!),
            ),

            // Lecture details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lecture.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (lecture.description != null) ...[
                      Text(
                        lecture.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.access_time,
                              'Duration',
                              _formatDuration(lecture.durationSeconds),
                            ),
                            const Divider(),
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Published',
                              _formatDate(lecture.createdAt),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
