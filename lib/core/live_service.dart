import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/lecture.dart';

// TODO: Add your Agora App ID here
const String AGORA_APP_ID = 'YOUR_AGORA_APP_ID_HERE';

// TODO: For production, implement token server
// This service currently uses Agora's dev mode (no token required)
// For production, you must:
// 1. Set up a token server (Node.js/Python/Go)
// 2. Implement getToken() method to fetch from your server
// 3. Enable token authentication in Agora console

class LiveClassService {
  late RtcEngine _engine;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;

  // Initialize Agora engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permissions
      await _requestPermissions();

      // Create Agora engine
      _engine = createAgoraRtcEngine();
      
      await _engine.initialize(RtcEngineContext(
        appId: AGORA_APP_ID,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Enable video
      await _engine.enableVideo();
      await _engine.enableAudio();

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize live class service: $e');
    }
  }

  // Request camera and microphone permissions
  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();
  }

  // Join a live class as broadcaster (host)
  Future<void> joinAsHost({
    required String channelName,
    required int uid,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Set client role as broadcaster
      await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Join channel
      // TODO: In production, replace null with token from your server
      await _engine.joinChannel(
        token: null, // Use token in production
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      throw Exception('Failed to join as host: $e');
    }
  }

  // Join a live class as audience (student)
  Future<void> joinAsAudience({
    required String channelName,
    required int uid,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      // Set client role as audience
      await _engine.setClientRole(role: ClientRoleType.clientRoleAudience);

      // Join channel
      // TODO: In production, replace null with token from your server
      await _engine.joinChannel(
        token: null, // Use token in production
        channelId: channelName,
        uid: uid,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      throw Exception('Failed to join as audience: $e');
    }
  }

  // Leave channel
  Future<void> leaveChannel() async {
    if (!_isInitialized) return;

    try {
      await _engine.leaveChannel();
    } catch (e) {
      throw Exception('Failed to leave channel: $e');
    }
  }

  // Toggle camera
  Future<void> toggleCamera(bool enabled) async {
    await _engine.enableLocalVideo(enabled);
  }

  // Toggle microphone
  Future<void> toggleMicrophone(bool enabled) async {
    await _engine.enableLocalAudio(enabled);
  }

  // Switch camera (front/back)
  Future<void> switchCamera() async {
    await _engine.switchCamera();
  }

  // Get engine instance (for UI widget)
  RtcEngine get engine => _engine;

  // Register event handlers
  void registerEventHandlers({
    Function(RtcConnection connection, int remoteUid, int elapsed)? onUserJoined,
    Function(RtcConnection connection, int remoteUid, UserOfflineReasonType reason)? onUserOffline,
    Function(ErrorCodeType err, String msg)? onError,
  }) {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: onUserJoined,
        onUserOffline: onUserOffline,
        onError: onError,
      ),
    );
  }

  // Create live session in Firestore
  Future<String> createLiveSession({
    required String courseId,
    required String title,
    required DateTime scheduledAt,
  }) async {
    try {
      final channelName = 'live_${DateTime.now().millisecondsSinceEpoch}';
      
      final session = LiveSession(
        id: '',
        courseId: courseId,
        title: title,
        scheduledAt: scheduledAt,
        channelName: channelName,
        isActive: false,
      );

      final docRef = await _firestore
          .collection('liveSessions')
          .add(session.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create live session: $e');
    }
  }

  // Start live session
  Future<void> startLiveSession(String sessionId) async {
    try {
      await _firestore.collection('liveSessions').doc(sessionId).update({
        'isActive': true,
        'startedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to start live session: $e');
    }
  }

  // End live session
  Future<void> endLiveSession(String sessionId) async {
    try {
      await _firestore.collection('liveSessions').doc(sessionId).update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to end live session: $e');
    }
  }

  // Get active live sessions
  Stream<List<LiveSession>> getActiveSessions() {
    return _firestore
        .collection('liveSessions')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LiveSession.fromFirestore(doc))
            .toList());
  }

  // Get scheduled sessions for a course
  Stream<List<LiveSession>> getScheduledSessions(String courseId) {
    return _firestore
        .collection('liveSessions')
        .where('courseId', isEqualTo: courseId)
        .where('scheduledAt', isGreaterThan: DateTime.now())
        .orderBy('scheduledAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LiveSession.fromFirestore(doc))
            .toList());
  }

  // Dispose engine
  Future<void> dispose() async {
    if (_isInitialized) {
      await _engine.leaveChannel();
      await _engine.release();
      _isInitialized = false;
    }
  }
}

// Alternative: Jitsi Meet integration (fallback option)
// Uncomment and use if you prefer Jitsi over Agora
/*
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class JitsiLiveService {
  final JitsiMeet _jitsiMeet = JitsiMeet();

  Future<void> joinMeeting({
    required String roomName,
    required String displayName,
    bool isHost = false,
  }) async {
    try {
      var options = JitsiMeetConferenceOptions(
        room: roomName,
        configOverrides: {
          "startWithAudioMuted": !isHost,
          "startWithVideoMuted": !isHost,
        },
        featureFlags: {
          "unsaferoomwarning.enabled": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: displayName,
        ),
      );

      await _jitsiMeet.join(options);
    } catch (e) {
      throw Exception('Failed to join Jitsi meeting: $e');
    }
  }
}
*/
