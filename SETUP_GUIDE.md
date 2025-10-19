# Quick Setup Guide for Harsh Learning App

This is a step-by-step quick reference guide to get the app running.

## Prerequisites Check

Before starting, make sure you have:

- ✅ Flutter SDK 3.7.0 or higher (`flutter --version`)
- ✅ Android Studio or Xcode installed
- ✅ Firebase account
- ✅ Agora account (free tier is fine for testing)

## 5-Minute Quick Start

### 1. Install Dependencies (1 min)

```bash
flutter pub get
```

### 2. Configure Firebase (2 min)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (will open browser to select project)
flutterfire configure

# Select or create a Firebase project
# Select platforms: Android, iOS, Web
```

This automatically:
- Creates `lib/firebase_options.dart`
- Downloads `google-services.json` and `GoogleService-Info.plist`
- Configures all platforms

### 3. Enable Firebase Services (1 min)

Go to [Firebase Console](https://console.firebase.google.com/):

1. **Authentication** → Enable:
   - ✅ Email/Password
   - ✅ Google Sign-In

2. **Firestore Database** → Create Database:
   - Start in **production mode**
   - Choose location closest to you

3. **Storage** → Get Started:
   - Start in **production mode**

### 4. Deploy Firebase Rules (30 sec)

```bash
firebase login
firebase init   # Select Firestore and Storage
firebase deploy --only firestore:rules,storage
```

### 5. Configure Agora (30 sec)

1. Go to [Agora Console](https://console.agora.io/)
2. Create a project (or use existing)
3. Copy your App ID
4. Edit `lib/core/live_service.dart`:
   ```dart
   const String AGORA_APP_ID = 'paste-your-app-id-here';
   ```

### 6. Run the App! (30 sec)

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web (for admin panel)
flutter run -d chrome
```

## First Time Setup

After the app runs:

1. **Sign up** with email/password
2. Go to **Firebase Console** → Firestore
3. Find your user in `users` collection
4. Change `role: "student"` to `role: "admin"`
5. Restart app - you'll see admin dashboard icon

## Create Sample Data

```bash
dart run seed_data.dart
```

This creates:
- 1 sample course
- 1 sample lecture
- 1 live session

## Common Issues & Fixes

### Issue: "Firebase not initialized"
**Fix:** Run `flutterfire configure` again

### Issue: "Google Sign-In not working" (Android)
**Fix:** 
1. Get SHA-1: `cd android && ./gradlew signingReport`
2. Add to Firebase Console → Project Settings → Your Apps → Android app
3. Re-download `google-services.json`

### Issue: "Build failed"
**Fix:**
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: "Agora video not showing"
**Fix:**
- Test on real device (not emulator)
- Check camera permissions are granted
- Verify App ID is correct

## What's Next?

1. ✅ Upload some real content:
   - Go to Admin Dashboard
   - Create courses
   - Upload videos and PDFs

2. ✅ Test live classes:
   - Schedule a live session
   - Join from student account

3. ✅ Customize:
   - Update app name in `pubspec.yaml`
   - Change package name in Android/iOS configs
   - Add your branding/colors

## Need More Help?

- 📖 Full README: See `README.md`
- 🐛 Issues: Check Firebase Console logs
- 💬 Support: Create GitHub issue with error logs

## Production Deployment

Before going live:

1. **Security:**
   - ✅ Update Firestore rules to production mode
   - ✅ Set up Agora token server
   - ✅ Enable Firebase App Check

2. **Build:**
   ```bash
   # Android
   flutter build appbundle --release
   
   # iOS
   flutter build ios --release
   ```

3. **Deploy:**
   - Upload to Play Store / App Store
   - Set up CI/CD (optional)

---

**Time to first run:** ~5 minutes
**Time to production-ready:** ~1-2 hours

Good luck! 🚀
