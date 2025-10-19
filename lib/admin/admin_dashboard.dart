import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: _checkAdminAccess(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data != true) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Access Denied'),
                  const SizedBox(height: 8),
                  const Text('You need admin privileges to access this page.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          );
        }

        return const _AdminDashboardContent();
      },
    );
  }

  Future<bool> _checkAdminAccess(WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) return false;
    return await authService.isAdmin(user.uid);
  }
}

class _AdminDashboardContent extends ConsumerWidget {
  const _AdminDashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats cards
            Row(
              children: [
                Expanded(child: _buildStatCard(context, 'courses', 'Courses')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard(context, 'lectures', 'Lectures')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard(context, 'users', 'Users')),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(context, 'liveSessions', 'Live Sessions'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            _buildActionCard(
              context,
              icon: Icons.school,
              title: 'Manage Courses',
              subtitle: 'Create, edit, and delete courses',
              onTap: () => context.push('/admin/courses'),
            ),
            const SizedBox(height: 12),

            _buildActionCard(
              context,
              icon: Icons.upload_file,
              title: 'Upload Content',
              subtitle: 'Upload PDFs and lecture videos',
              onTap: () {
                // Show course selection dialog
                _showCourseSelectionDialog(context, 'upload');
              },
            ),
            const SizedBox(height: 12),

            _buildActionCard(
              context,
              icon: Icons.live_tv,
              title: 'Schedule Live Class',
              subtitle: 'Create and manage live sessions',
              onTap: () {
                // Show course selection dialog
                _showCourseSelectionDialog(context, 'schedule');
              },
            ),
            const SizedBox(height: 12),

            _buildActionCard(
              context,
              icon: Icons.analytics,
              title: 'View Analytics',
              subtitle: 'See user engagement and statistics',
              onTap: () {
                // TODO: Navigate to analytics screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String collection, String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(collection).snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;

            return Column(
              children: [
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(label),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showCourseSelectionDialog(
    BuildContext context,
    String action,
  ) async {
    final courses = await FirebaseFirestore.instance
        .collection('courses')
        .get()
        .then((snapshot) => snapshot.docs);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Course'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return ListTile(
                title: Text(course['title']),
                onTap: () {
                  Navigator.pop(context);
                  if (action == 'upload') {
                    _showUploadTypeDialog(context, course.id);
                  } else if (action == 'schedule') {
                    context.push('/admin/schedule-live?courseId=${course.id}');
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUploadTypeDialog(BuildContext context, String courseId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Upload PDF'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/upload-pdf?courseId=$courseId');
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Upload Lecture Video'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/upload-lecture?courseId=$courseId');
              },
            ),
          ],
        ),
      ),
    );
  }
}
