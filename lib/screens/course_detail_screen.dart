import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../models/course.dart';
import '../models/lecture.dart';
import '../widgets/video_card.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
  });

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Course not found'));
          }

          final course = Course.fromFirestore(snapshot.data!);

          return CustomScrollView(
            slivers: [
              // App bar with course image
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    course.title,
                    style: const TextStyle(
                      shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                    ),
                  ),
                  background: course.thumbnailUrl != null
                      ? Image.network(
                          course.thumbnailUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.school, size: 80),
                        ),
                ),
              ),

              // Tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Lectures'),
                      Tab(text: 'Materials'),
                    ],
                  ),
                ),
              ),

              // Tab content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(course),
                    _buildLecturesTab(course),
                    _buildMaterialsTab(course),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(Course course) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this course',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(course.description),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(Icons.person, 'Instructor', course.instructor),
                  const Divider(),
                  _buildInfoRow(
                    Icons.people,
                    'Students Enrolled',
                    course.enrolledCount.toString(),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Created',
                    _formatDate(course.createdAt),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturesTab(Course course) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lectures')
          .where('courseId', isEqualTo: course.id)
          .where('isPublished', isEqualTo: true)
          .orderBy('orderIndex')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final lectures = snapshot.data!.docs
            .map((doc) => Lecture.fromFirestore(doc))
            .toList();

        if (lectures.isEmpty) {
          return const Center(child: Text('No lectures available yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lectures.length,
          itemBuilder: (context, index) {
            return VideoCard(
              lecture: lectures[index],
              onTap: () => context.push('/lecture/${lectures[index].id}'),
            );
          },
        );
      },
    );
  }

  Widget _buildMaterialsTab(Course course) {
    if (course.pdfUrls.isEmpty) {
      return const Center(child: Text('No materials available yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: course.pdfUrls.length,
      itemBuilder: (context, index) {
        final pdfUrl = course.pdfUrls[index];
        final fileName = pdfUrl.split('/').last.split('?').first;

        return Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, size: 40),
            title: Text(fileName),
            subtitle: const Text('PDF Document'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              context.push(
                '/pdf-viewer?url=${Uri.encodeComponent(pdfUrl)}&title=${Uri.encodeComponent(fileName)}',
              );
            },
          ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
