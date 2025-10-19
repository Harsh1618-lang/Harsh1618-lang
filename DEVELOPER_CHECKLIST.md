# Developer Checklist - Harsh LMS Setup

Use this checklist to ensure all setup steps are completed correctly.

## 🎯 Phase 1: Initial Setup (15 minutes)

### Flutter Environment
- [ ] Flutter SDK installed and in PATH
  ```bash
  flutter --version
  # Should show Flutter >=3.7.0
  ```
- [ ] Run Flutter doctor
  ```bash
  flutter doctor
  # Fix any issues shown
  ```
- [ ] Install dependencies
  ```bash
  cd harsh
  flutter pub get
  ```

### IDE Setup
- [ ] Install recommended IDE (VS Code or Android Studio)
- [ ] Install Flutter extension
- [ ] Install Dart extension

## 🔥 Phase 2: Firebase Setup (10 minutes)

### Create Firebase Project
- [ ] Go to https://console.firebase.google.com/
- [ ] Click "Add project"
- [ ] Name it (e.g., "harsh-learning-dev")
- [ ] Enable Google Analytics (optional)
- [ ] Create project

### Enable Firebase Services
- [ ] **Authentication**
  - [ ] Go to Authentication → Sign-in method
  - [ ] Enable Email/Password
  - [ ] Enable Google Sign-In
  - [ ] Add OAuth consent screen info

- [ ] **Firestore Database**
  - [ ] Go to Firestore Database
  - [ ] Click "Create database"
  - [ ] Start in **production mode**
  - [ ] Choose location (nearest to you)
  - [ ] Click "Enable"

- [ ] **Firebase Storage**
  - [ ] Go to Storage
  - [ ] Click "Get started"
  - [ ] Start in **production mode**
  - [ ] Click "Done"

- [ ] **Cloud Messaging** (for notifications)
  - [ ] Go to Cloud Messaging
  - [ ] Enable if not already enabled

### Configure FlutterFire
- [ ] Install FlutterFire CLI
  ```bash
  dart pub global activate flutterfire_cli
  ```
- [ ] Configure project
  ```bash
  flutterfire configure
  ```
- [ ] Select your Firebase project
- [ ] Select platforms: Android, iOS, Web
- [ ] Verify `lib/firebase_options.dart` was created
- [ ] Verify `android/app/google-services.json` was created
- [ ] Verify `ios/Runner/GoogleService-Info.plist` was created

### Deploy Firebase Rules
- [ ] Install Firebase CLI
  ```bash
  npm install -g firebase-tools
  ```
- [ ] Login to Firebase
  ```bash
  firebase login
  ```
- [ ] Initialize Firebase
  ```bash
  firebase init
  # Select: Firestore, Storage
  # Use existing project
  # Use default file names
  ```
- [ ] Replace rules files
  - [ ] Copy `firebase_rules/firestore.rules` to `firestore.rules`
  - [ ] Copy `firebase_rules/storage.rules` to `storage.rules`
- [ ] Deploy rules
  ```bash
  firebase deploy --only firestore:rules,storage
  ```
- [ ] Verify rules deployed successfully

## 📱 Phase 3: Agora Setup (5 minutes)

### Get Agora Credentials
- [ ] Go to https://console.agora.io/
- [ ] Sign up / Sign in
- [ ] Create a new project
- [ ] Select "Secured mode: APP ID + Token" (can use dev mode for testing)
- [ ] Copy your App ID

### Configure Agora in Code
- [ ] Open `lib/core/live_service.dart`
- [ ] Find line: `const String AGORA_APP_ID = 'YOUR_AGORA_APP_ID_HERE';`
- [ ] Replace with: `const String AGORA_APP_ID = 'your-actual-app-id';`
- [ ] Save file

### Production Setup (Later)
- [ ] Set up token server (see Agora docs)
- [ ] Update `getToken()` method
- [ ] Switch to secured mode in Agora console

## 🤖 Phase 4: Android Setup (10 minutes)

### Update Package Name (Optional)
- [ ] Open `android/app/build.gradle`
- [ ] Change `applicationId "com.yourname.harsh"` to your package name
- [ ] Update in `AndroidManifest.xml`
- [ ] Update in `MainActivity.kt`

### Add SHA-1 Fingerprint (for Google Sign-In)
- [ ] Get debug SHA-1
  ```bash
  cd android
  ./gradlew signingReport
  ```
- [ ] Copy SHA-1 fingerprint
- [ ] Go to Firebase Console → Project Settings → Your Apps → Android
- [ ] Add SHA-1 fingerprint
- [ ] Download new `google-services.json`
- [ ] Replace `android/app/google-services.json`

### Test Android Build
- [ ] Connect Android device or start emulator
- [ ] Run app
  ```bash
  flutter run
  ```
- [ ] Verify app launches
- [ ] Test permissions (camera, microphone)

## 🍎 Phase 5: iOS Setup (10 minutes)

### Update Bundle Identifier (Optional)
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Select Runner → General
- [ ] Update Bundle Identifier to your chosen ID
- [ ] Match with Firebase iOS app

### Configure Signing
- [ ] In Xcode, select Runner → Signing & Capabilities
- [ ] Select your team
- [ ] Enable "Automatically manage signing"

### Add Required Capabilities
- [ ] In Xcode → Signing & Capabilities
- [ ] Click "+ Capability"
- [ ] Add: Push Notifications
- [ ] Add: Background Modes → Remote notifications

### Test iOS Build
- [ ] Connect iOS device or start simulator
- [ ] Run app
  ```bash
  flutter run -d ios
  ```
- [ ] Verify app launches
- [ ] Test permissions

## 🌐 Phase 6: Web Setup (5 minutes)

### Verify Web Configuration
- [ ] Check `web/index.html` exists
- [ ] Check `web/manifest.json` exists

### Test Web Build
- [ ] Run on Chrome
  ```bash
  flutter run -d chrome
  ```
- [ ] Verify admin panel loads
- [ ] Test responsive design

## 👤 Phase 7: Create Admin User (5 minutes)

### Sign Up First User
- [ ] Run the app
- [ ] Go to Sign Up
- [ ] Create account with email/password
- [ ] Remember email used

### Promote to Admin
- [ ] Go to Firebase Console → Firestore Database
- [ ] Click on `users` collection
- [ ] Find your user document
- [ ] Click to edit
- [ ] Change `role` from `"student"` to `"admin"`
- [ ] Save

### Verify Admin Access
- [ ] Restart the app
- [ ] Sign in with admin account
- [ ] Verify admin icon appears in app bar
- [ ] Click admin icon
- [ ] Verify admin dashboard loads

## 📦 Phase 8: Create Sample Data (2 minutes)

### Run Seed Script
- [ ] Run seed script
  ```bash
  dart run seed_data.dart
  ```
- [ ] Verify success message
- [ ] Note the created Course ID

### Verify Data in Firebase
- [ ] Go to Firebase Console → Firestore
- [ ] Check `courses` collection has 1 document
- [ ] Check `lectures` collection has 1 document
- [ ] Check `liveSessions` collection has 1 document

### Test in App
- [ ] Open app as student
- [ ] Verify course appears on home screen
- [ ] Click course
- [ ] Verify lecture appears
- [ ] Try playing lecture
- [ ] Try viewing PDF

## 🧪 Phase 9: Testing (10 minutes)

### Run Unit Tests
- [ ] Run all tests
  ```bash
  flutter test
  ```
- [ ] Verify tests pass (or check failures)

### Manual Testing Checklist

#### Authentication
- [ ] Sign up with email/password
- [ ] Sign in with email/password
- [ ] Sign out
- [ ] Sign in with Google (Android)
- [ ] Sign in with Google (iOS)
- [ ] Password reset (optional)

#### Student Features
- [ ] View courses list
- [ ] Open course details
- [ ] View course overview
- [ ] View lectures list
- [ ] Play video lecture
- [ ] View PDF material
- [ ] Download PDF
- [ ] View live classes list
- [ ] View profile

#### Admin Features (as admin user)
- [ ] Access admin dashboard
- [ ] View stats
- [ ] Create new course
- [ ] Edit course
- [ ] Upload thumbnail
- [ ] Upload PDF
- [ ] Upload lecture video
- [ ] Schedule live session
- [ ] Start live session
- [ ] End live session

#### UI/UX
- [ ] Toggle dark mode
- [ ] Test system theme
- [ ] Test on different screen sizes
- [ ] Test landscape orientation
- [ ] Test pull-to-refresh

#### Permissions
- [ ] Camera permission (live classes)
- [ ] Microphone permission (live classes)
- [ ] Storage permission (downloads)
- [ ] Notification permission

## 🎨 Phase 10: Customization (Optional)

### Branding
- [ ] Update app name in `pubspec.yaml`
- [ ] Update display name in `AndroidManifest.xml`
- [ ] Update display name in `Info.plist`
- [ ] Create app icons (use flutter_launcher_icons package)
- [ ] Update theme colors in `main.dart`

### Content
- [ ] Add real courses
- [ ] Add real lectures
- [ ] Upload actual PDFs
- [ ] Upload actual videos
- [ ] Add instructor information

## 🚀 Phase 11: Production Preparation

### Security
- [ ] Review Firestore rules
- [ ] Review Storage rules
- [ ] Enable Firebase App Check
- [ ] Set up rate limiting
- [ ] Implement proper error handling

### Performance
- [ ] Test with many courses/lectures
- [ ] Implement pagination if needed
- [ ] Optimize images
- [ ] Test upload/download speeds

### Monitoring
- [ ] Set up Firebase Crashlytics
- [ ] Set up Firebase Performance Monitoring
- [ ] Set up error tracking (Sentry, etc.)

### Cloud Functions (Optional but Recommended)
- [ ] Create function to send scheduled notifications
- [ ] Create function to process notification requests
- [ ] Create function to clean up old analytics
- [ ] Create function to generate thumbnails

### Final Checks
- [ ] All TODOs in code resolved
- [ ] All secrets removed from git
- [ ] `.gitignore` properly configured
- [ ] Documentation updated
- [ ] License added
- [ ] Privacy policy added
- [ ] Terms of service added

## 📊 Phase 12: Build for Production

### Android Release
- [ ] Create keystore
  ```bash
  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] Create `android/key.properties`
- [ ] Update `android/app/build.gradle` with signing config
- [ ] Build release APK
  ```bash
  flutter build apk --release
  ```
- [ ] Test APK on real device
- [ ] Build App Bundle
  ```bash
  flutter build appbundle --release
  ```

### iOS Release
- [ ] Create App Store Connect account
- [ ] Create app in App Store Connect
- [ ] Configure code signing with distribution certificate
- [ ] Build for release
  ```bash
  flutter build ios --release
  ```
- [ ] Archive in Xcode
- [ ] Upload to App Store Connect

### Web Release
- [ ] Build web
  ```bash
  flutter build web --release
  ```
- [ ] Deploy to hosting (Firebase Hosting, Vercel, etc.)

## ✅ Final Verification

### Functionality
- [ ] All features work on Android
- [ ] All features work on iOS
- [ ] Admin panel works on web
- [ ] Push notifications work
- [ ] Live classes work
- [ ] Video playback works
- [ ] PDF viewing works
- [ ] File uploads work
- [ ] File downloads work

### Performance
- [ ] App startup time < 3 seconds
- [ ] No memory leaks
- [ ] Smooth animations
- [ ] No frame drops

### Security
- [ ] No hardcoded secrets
- [ ] All API keys in secure location
- [ ] Firebase rules tested
- [ ] Storage rules tested

## 🎉 Launch Ready!

If all items are checked, your app is ready for:
- [ ] Beta testing
- [ ] Production deployment
- [ ] App store submission

---

## 📞 Support

If you encounter issues:
1. Check README.md for detailed explanations
2. Check SETUP_GUIDE.md for quick fixes
3. Check Firebase Console logs
4. Check Flutter doctor output
5. Create GitHub issue with logs

## 🔄 Regular Maintenance

Weekly:
- [ ] Check Firebase usage (auth, storage, Firestore)
- [ ] Check Agora usage/billing
- [ ] Review analytics data
- [ ] Check for user reports

Monthly:
- [ ] Update Flutter & dependencies
- [ ] Review security rules
- [ ] Backup Firestore data
- [ ] Review crash reports

---

**Good luck with your Harsh Learning Management System! 🚀**
