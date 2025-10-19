# Harsh Learning Management System

A comprehensive Flutter-based Learning Management System (LMS) with live classes, video lectures, PDF materials, and a full-featured admin panel.

## Features

### Student Features
- 🔐 **Authentication**: Email/password and Google Sign-In via Firebase Auth
- 📚 **Course Browsing**: View published courses with detailed information
- 📹 **Video Lectures**: Watch recorded lectures with video player controls
- 📄 **PDF Viewer**: View and download course materials
- 🎥 **Live Classes**: Join live classes powered by Agora
- 🌓 **Dark Mode**: System-based or manual theme toggle
- 🔔 **Push Notifications**: Get notified about new content and live classes
- 👤 **Profile Management**: Update profile and preferences

### Admin Features
- 📊 **Dashboard**: Overview of courses, lectures, users, and sessions
- ➕ **Course Management**: Create, edit, and delete courses
- 📤 **Content Upload**: Upload PDF materials and lecture videos
- 📅 **Live Class Scheduling**: Schedule and manage live sessions
- 🔒 **Role-Based Access**: Admin-only access control
- 🖼️ **Thumbnail Upload**: Add course thumbnails

### Technical Features
- 🏗️ **Modular Architecture**: Clean separation of concerns with providers
- 🎨 **Material Design 3**: Modern UI with adaptive theming
- 🔄 **Real-time Updates**: Firestore streams for live data
- 📊 **Analytics**: Event logging for user engagement
- 🌐 **Cross-Platform**: Android, iOS, and Web support

## Architecture

### Project Structure
```
lib/
├── core/                    # Core services
│   ├── auth_service.dart
│   ├── storage_service.dart
│   ├── live_service.dart
│   └── notification_service.dart
├── models/                  # Data models
│   ├── course.dart
│   ├── lecture.dart
│   └── user.dart
├── screens/                 # Student screens
│   ├── splash_screen.dart
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── course_detail_screen.dart
│   ├── pdf_viewer_screen.dart
│   ├── lecture_player_screen.dart
│   ├── live_list_screen.dart
│   └── profile_screen.dart
├── admin/                   # Admin screens
│   ├── admin_dashboard.dart
│   ├── manage_courses_screen.dart
│   ├── upload_pdf_screen.dart
│   ├── upload_lecture_screen.dart
│   └── schedule_live_screen.dart
├── widgets/                 # Reusable widgets
│   ├── course_card.dart
│   └── video_card.dart
└── main.dart               # App entry point
```

### State Management
- **Riverpod** for dependency injection and state management
- Provider-based architecture for services
- Stream-based real-time updates from Firestore

### Firebase Services
- **Firebase Auth**: User authentication
- **Cloud Firestore**: NoSQL database for metadata
- **Firebase Storage**: File storage for videos and PDFs
- **Firebase Cloud Messaging**: Push notifications

## Firestore Schema

### Collections

#### `users`
```json
{
  "email": "user@example.com",
  "displayName": "John Doe",
  "photoUrl": "https://...",
  "role": "student", // or "admin"
  "createdAt": Timestamp,
  "enrolledCourses": ["courseId1", "courseId2"],
  "fcmToken": "..."
}
```

#### `courses`
```json
{
  "title": "Flutter Development",
  "description": "Learn Flutter from scratch",
  "thumbnailUrl": "https://...",
  "instructor": "Jane Smith",
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  "isPublished": true,
  "pdfUrls": ["https://...", "https://..."],
  "enrolledCount": 42,
  "tags": ["Flutter", "Mobile"]
}
```

#### `lectures`
```json
{
  "courseId": "course123",
  "title": "Introduction to Flutter",
  "description": "Overview of Flutter framework",
  "videoUrl": "https://...",
  "thumbnailUrl": "https://...",
  "durationSeconds": 3600,
  "orderIndex": 0,
  "createdAt": Timestamp,
  "isPublished": true,
  "type": "recorded" // or "live"
}
```

#### `liveSessions`
```json
{
  "courseId": "course123",
  "title": "Live Q&A Session",
  "scheduledAt": Timestamp,
  "startedAt": Timestamp,
  "endedAt": Timestamp,
  "channelName": "live_123456789",
  "isActive": true,
  "recordingUrl": "https://..."
}
```

#### `analytics`
```json
{
  "eventName": "lecture_played",
  "data": {
    "userId": "user123",
    "courseId": "course123",
    "lectureId": "lecture123"
  },
  "timestamp": Timestamp
}
```

## Setup Instructions

### Prerequisites
- Flutter SDK >= 3.7.0
- Dart SDK >= 3.0.0
- Firebase project with Firestore, Storage, and Authentication enabled
- Agora account (for live classes)
- Android Studio / Xcode for mobile development

### Step 1: Clone and Install Dependencies

```bash
# Clone the repository
git clone <repository-url>
cd harsh

# Install Flutter dependencies
flutter pub get
```

### Step 2: Firebase Setup

1. **Create a Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project
   - Enable Google Analytics (optional)

2. **Enable Firebase Services**
   - **Authentication**: Enable Email/Password and Google Sign-In
   - **Firestore Database**: Create database in production mode
   - **Storage**: Enable Firebase Storage
   - **Cloud Messaging**: Enable FCM for push notifications

3. **Configure FlutterFire**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli

   # Configure Firebase for your Flutter app
   flutterfire configure
   ```
   This will:
   - Generate `lib/firebase_options.dart`
   - Download `google-services.json` (Android)
   - Download `GoogleService-Info.plist` (iOS)
   - Configure Firebase for Web

4. **Deploy Firebase Rules**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools

   # Login to Firebase
   firebase login

   # Initialize Firebase in project
   firebase init

   # Deploy Firestore rules
   firebase deploy --only firestore:rules

   # Deploy Storage rules
   firebase deploy --only storage
   ```

### Step 3: Agora Setup

1. **Create Agora Account**
   - Go to [Agora Console](https://console.agora.io/)
   - Create a new project
   - Get your App ID

2. **Configure Agora**
   - Open `lib/core/live_service.dart`
   - Replace `YOUR_AGORA_APP_ID_HERE` with your actual App ID
   ```dart
   const String AGORA_APP_ID = 'your-actual-app-id';
   ```

3. **Production Token Server** (Required for production)
   - Agora requires token authentication in production
   - Set up a token server (Node.js/Python/Go)
   - Implement `getToken()` method in `LiveClassService`
   - See [Agora Token Server](https://docs.agora.io/en/video-calling/get-started/authentication-workflow)

### Step 4: Android Configuration

1. **Update `android/app/build.gradle`**
   ```gradle
   android {
       defaultConfig {
           applicationId "com.yourname.harsh"
           minSdkVersion 21
           targetSdkVersion 34
       }
   }
   ```

2. **Add `google-services.json`**
   - Place in `android/app/`

3. **Update Permissions in `AndroidManifest.xml`**
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
   ```

### Step 5: iOS Configuration

1. **Update `ios/Runner/Info.plist`**
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>Camera access is required for live classes</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>Microphone access is required for live classes</string>
   ```

2. **Add `GoogleService-Info.plist`**
   - Place in `ios/Runner/`

3. **Update iOS deployment target**
   - Open `ios/Podfile`
   - Set `platform :ios, '12.0'` or higher

### Step 6: Web Configuration

Web build is already configured for admin panel use. To run:

```bash
flutter run -d chrome
```

### Step 7: Create Admin User

After first run, you need to manually set a user as admin in Firestore:

1. Sign up with an email/password
2. Go to Firebase Console → Firestore
3. Find your user document in `users` collection
4. Change `role` field from `"student"` to `"admin"`

### Step 8: Seed Sample Data (Optional)

```bash
# Run the seed script
dart run seed_data.dart
```

This creates:
- 1 sample course
- 1 sample lecture
- Sample PDF URL

## Running the App

### Development

```bash
# Run on Android
flutter run

# Run on iOS
flutter run -d ios

# Run on Web
flutter run -d chrome

# Run with hot reload
flutter run --hot
```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/auth_service_test.dart
```

## Environment Variables & Secrets

**IMPORTANT**: Never commit the following files:
- `lib/firebase_options.dart` (after adding real credentials)
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- Any files with API keys or secrets

Add to `.gitignore`:
```
# Firebase
lib/firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist

# Secrets
*.env
.env.*
```

## Production Checklist

Before deploying to production:

- [ ] Replace all `YOUR_*_HERE` placeholders with real credentials
- [ ] Set up Agora token server and implement token authentication
- [ ] Update Firebase rules to production mode
- [ ] Enable Firebase App Check
- [ ] Set up proper error tracking (Firebase Crashlytics, Sentry)
- [ ] Implement rate limiting for uploads
- [ ] Set up Cloud Functions for:
  - [ ] Sending scheduled notifications
  - [ ] Processing notification requests
  - [ ] Cleaning up old analytics data
- [ ] Configure proper CORS for Firebase Storage
- [ ] Set up proper backup strategy for Firestore
- [ ] Implement proper file size limits
- [ ] Add proper loading states and error handling
- [ ] Test on real devices (Android & iOS)
- [ ] Perform security audit
- [ ] Set up CI/CD pipeline

## Troubleshooting

### Common Issues

1. **Firebase initialization error**
   - Ensure `flutterfire configure` was run
   - Check that Firebase project matches the app bundle ID

2. **Agora video not showing**
   - Verify App ID is correct
   - Check camera/microphone permissions
   - Ensure you're testing on a real device (not emulator)

3. **PDF viewer not loading**
   - Check internet connection
   - Verify Firebase Storage rules allow read access
   - Check PDF URL is valid

4. **Build errors**
   - Run `flutter clean && flutter pub get`
   - Update Flutter: `flutter upgrade`
   - Check minimum SDK versions match

5. **Google Sign-In not working**
   - Add SHA-1 fingerprint to Firebase Console
   - Enable Google Sign-In in Firebase Auth
   - Configure OAuth consent screen

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `flutter test`
5. Submit a pull request

## License

This project is provided as-is for educational purposes.

## Support

For issues and questions:
- Check existing GitHub issues
- Create a new issue with:
  - Flutter version (`flutter --version`)
  - Device/emulator details
  - Error logs
  - Steps to reproduce

## Roadmap

Future enhancements:
- [ ] Offline mode with local caching
- [ ] Course progress tracking
- [ ] Quizzes and assignments
- [ ] Discussion forums
- [ ] Payment integration
- [ ] Certificate generation
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Screen recording for lectures
- [ ] Live chat during classes
- [ ] Whiteboard for live sessions

---

Built with ❤️ using Flutter and Firebase
