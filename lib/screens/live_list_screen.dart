import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/lecture.dart';
import '../main.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class LiveListScreen extends ConsumerStatefulWidget {
  const LiveListScreen({super.key});

  @override
  ConsumerState<LiveListScreen> createState() => _LiveListScreenState();
}

class _LiveListScreenState extends ConsumerState<LiveListScreen> {
  @override
  Widget build(BuildContext context) {
    final liveService = ref.read(liveServiceProvider);

    return Scaffold(
      body: StreamBuilder<List<LiveSession>>(
        stream: liveService.getActiveSessions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data ?? [];

          if (sessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_call_outlined, size: 80),
                  SizedBox(height: 16),
                  Text('No live classes at the moment'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              return _LiveSessionCard(session: sessions[index]);
            },
          );
        },
      ),
    );
  }
}

class _LiveSessionCard extends ConsumerWidget {
  final LiveSession session;

  const _LiveSessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.live_tv, color: Colors.white),
        ),
        title: Text(session.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('LIVE', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 4),
            Text(_formatTime(session.scheduledAt)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _joinLiveSession(context, ref),
      ),
    );
  }

  Future<void> _joinLiveSession(BuildContext context, WidgetRef ref) async {
    try {
      final liveService = ref.read(liveServiceProvider);
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;

      if (user == null) return;

      // Show loading dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Join as audience (students)
      await liveService.joinAsAudience(
        channelName: session.channelName,
        uid: user.uid.hashCode,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        // Navigate to live class screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => _LiveClassScreen(
              session: session,
              liveService: liveService,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _LiveClassScreen extends StatefulWidget {
  final LiveSession session;
  final LiveClassService liveService;

  const _LiveClassScreen({
    required this.session,
    required this.liveService,
  });

  @override
  State<_LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<_LiveClassScreen> {
  final Set<int> _remoteUsers = {};
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _registerEventHandlers();
  }

  void _registerEventHandlers() {
    widget.liveService.registerEventHandlers(
      onUserJoined: (connection, remoteUid, elapsed) {
        setState(() => _remoteUsers.add(remoteUid));
      },
      onUserOffline: (connection, remoteUid, reason) {
        setState(() => _remoteUsers.remove(remoteUid));
      },
      onError: (err, msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $msg')),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.liveService.leaveChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.title),
        actions: [
          IconButton(
            icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
            onPressed: () {
              setState(() => _isMuted = !_isMuted);
              widget.liveService.toggleMicrophone(!_isMuted);
            },
          ),
        ],
      ),
      body: Center(
        child: _remoteUsers.isEmpty
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Waiting for host...'),
                ],
              )
            : Stack(
                children: [
                  // Main video view
                  AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: widget.liveService.engine,
                      canvas: VideoCanvas(uid: _remoteUsers.first),
                      connection: RtcConnection(
                        channelId: widget.session.channelName,
                      ),
                    ),
                  ),
                  // Viewer count
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${_remoteUsers.length} viewers',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
