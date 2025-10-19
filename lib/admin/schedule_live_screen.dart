import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../models/course.dart';
import '../models/lecture.dart';

class ScheduleLiveScreen extends ConsumerStatefulWidget {
  final String courseId;

  const ScheduleLiveScreen({
    super.key,
    required this.courseId,
  });

  @override
  ConsumerState<ScheduleLiveScreen> createState() => _ScheduleLiveScreenState();
}

class _ScheduleLiveScreenState extends ConsumerState<ScheduleLiveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Live Class'),
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

                  // Session title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Session Title',
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

                  // Date picker
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      subtitle: Text(_formatDate(_selectedDate)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Time picker
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Time'),
                      subtitle: Text(_selectedTime.format(context)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _pickTime,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Schedule button
                  ElevatedButton.icon(
                    onPressed: _scheduleSession,
                    icon: const Icon(Icons.schedule),
                    label: const Text('Schedule Live Session'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Upcoming sessions
                  _buildUpcomingSessions(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingSessions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Sessions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<LiveSession>>(
          stream: ref.read(liveServiceProvider).getScheduledSessions(widget.courseId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sessions = snapshot.data!;

            if (sessions.isEmpty) {
              return const Center(child: Text('No upcoming sessions.'));
            }

            return Column(
              children: sessions.map((session) {
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.live_tv),
                    ),
                    title: Text(session.title),
                    subtitle: Text(
                      '${_formatDate(session.scheduledAt)} at ${_formatTime(session.scheduledAt)}',
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.play_arrow),
                            title: Text('Start Now'),
                          ),
                          onTap: () => _startSession(session),
                        ),
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.stop),
                            title: Text('End Session'),
                          ),
                          onTap: () => _endSession(session),
                        ),
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Delete'),
                          ),
                          onTap: () => _deleteSession(session),
                        ),
                      ],
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

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _scheduleSession() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final liveService = ref.read(liveServiceProvider);
      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await liveService.createLiveSession(
        courseId: widget.courseId,
        title: _titleController.text,
        scheduledAt: scheduledAt,
      );

      // Schedule notification reminder
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.scheduleLiveClassReminder(
        courseId: widget.courseId,
        title: _titleController.text,
        scheduledAt: scheduledAt,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live session scheduled successfully')),
        );

        // Clear form
        _titleController.clear();
        setState(() {
          _selectedDate = DateTime.now();
          _selectedTime = TimeOfDay.now();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _startSession(LiveSession session) async {
    try {
      final liveService = ref.read(liveServiceProvider);
      await liveService.startLiveSession(session.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live session started')),
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

  Future<void> _endSession(LiveSession session) async {
    try {
      final liveService = ref.read(liveServiceProvider);
      await liveService.endLiveSession(session.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live session ended')),
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

  Future<void> _deleteSession(LiveSession session) async {
    try {
      await FirebaseFirestore.instance
          .collection('liveSessions')
          .doc(session.id)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deleted')),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
