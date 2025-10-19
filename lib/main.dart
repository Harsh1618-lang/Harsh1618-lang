import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/auth_service.dart';
import 'core/storage_service.dart';
import 'core/live_service.dart';
import 'core/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'screens/lecture_player_screen.dart';
import 'screens/live_list_screen.dart';
import 'screens/profile_screen.dart';
import 'admin/admin_dashboard.dart';
import 'admin/manage_courses_screen.dart';
import 'admin/upload_pdf_screen.dart';
import 'admin/upload_lecture_screen.dart';
import 'admin/schedule_live_screen.dart';
import 'package:go_router/go_router.dart';

// Providers for services
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final liveServiceProvider = Provider<LiveClassService>((ref) => LiveClassService());
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode');
    if (themeModeString != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.toString() == themeModeString,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString());
  }

  void toggleTheme() {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(newMode);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = _createRouter(ref);

    return MaterialApp.router(
      title: 'Harsh Learning',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }

  // Light theme
  static final _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
    ),
  );

  // Dark theme
  static final _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
    ),
  );

  // Create router
  GoRouter _createRouter(WidgetRef ref) {
    final authService = ref.read(authServiceProvider);

    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) async {
        final user = authService.currentUser;
        final isAuthPage = state.matchedLocation == '/auth';
        final isSplashPage = state.matchedLocation == '/splash';

        if (isSplashPage) return null;

        if (user == null && !isAuthPage) {
          return '/auth';
        }

        if (user != null && isAuthPage) {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/course/:id',
          builder: (context, state) {
            final courseId = state.pathParameters['id']!;
            return CourseDetailScreen(courseId: courseId);
          },
        ),
        GoRoute(
          path: '/pdf-viewer',
          builder: (context, state) {
            final pdfUrl = state.uri.queryParameters['url']!;
            final title = state.uri.queryParameters['title'] ?? 'PDF Viewer';
            return PDFViewerScreen(pdfUrl: pdfUrl, title: title);
          },
        ),
        GoRoute(
          path: '/lecture/:id',
          builder: (context, state) {
            final lectureId = state.pathParameters['id']!;
            return LecturePlayerScreen(lectureId: lectureId);
          },
        ),
        GoRoute(
          path: '/live',
          builder: (context, state) => const LiveListScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        // Admin routes
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboard(),
        ),
        GoRoute(
          path: '/admin/courses',
          builder: (context, state) => const ManageCoursesScreen(),
        ),
        GoRoute(
          path: '/admin/upload-pdf',
          builder: (context, state) {
            final courseId = state.uri.queryParameters['courseId']!;
            return UploadPDFScreen(courseId: courseId);
          },
        ),
        GoRoute(
          path: '/admin/upload-lecture',
          builder: (context, state) {
            final courseId = state.uri.queryParameters['courseId']!;
            return UploadLectureScreen(courseId: courseId);
          },
        ),
        GoRoute(
          path: '/admin/schedule-live',
          builder: (context, state) {
            final courseId = state.uri.queryParameters['courseId']!;
            return ScheduleLiveScreen(courseId: courseId);
          },
        ),
      ],
    );
  }
}
