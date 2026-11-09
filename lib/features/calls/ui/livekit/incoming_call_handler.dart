import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart' as fci_entities;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../bloc/livekit/call_bloc.dart';
import '../../bloc/livekit/call_event.dart';
import '../../../../core/navigation/navigation_service.dart';

class IncomingCallHandler {
  static IncomingCallHandler? _instance;
  static IncomingCallHandler get instance => _instance ??= IncomingCallHandler._();

  IncomingCallHandler._();

  BuildContext? _context;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  bool _isInitialized = false;

  /// Early initialization for FCM handling (before runApp, no context needed)
  void initializeEarly() {
    if (_isInitialized) return;
    _setupFCMHandler(); // Setup listeners without context
    _isInitialized = true;
  }

  /// Full initialization with context for navigation
  void initialize(BuildContext context) {
    if (_isInitialized) {
      _context = context; // Update context for navigation
      return;
    }
    _context = context;
    _setupFCMHandler();
    _isInitialized = true;
  }

  void dispose() {
    _fcmSubscription?.cancel();
    _isInitialized = false;
  }

  void _setupFCMHandler() {
    // Handle FCM messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // // Handle FCM messages when app is in background/terminated
    // FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // // Handle initial message if app was terminated
    // FirebaseMessaging.instance.getInitialMessage().then(_handleBackgroundMessage);
  }

  // Voice-only app: helper to detect incoming call from various payload types
  bool _isIncomingCall(Map<String, dynamic> data) {
    final type = data['type'];
    final hasCallFields = data['callId'] != null && data['callerId'] != null &&
                          data['callerName'] != null && data['token'] != null &&
                          data['roomName'] != null && data['livekitUrl'] != null;

    // Accept 'call_incoming', 'incoming_call', 'video', 'audio' - all treated as voice calls
    // Backward compatibility: backend may send 'video' or 'audio' as call type
    return (type == 'incoming_call' || type == 'call_incoming' ||
            type == 'video' || type == 'audio') && hasCallFields;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    if (_isIncomingCall(data)) {
      _showIncomingCall(data);
    } else if (data['type'] == 'call_accepted') {
      _handleCallAccepted(data);
    }
  }

  void _handleBackgroundMessage(RemoteMessage? message) {
    if (message == null) return;
    final data = message.data;
    if (_isIncomingCall(data)) {
      _showIncomingCall(data);
    } else if (data['type'] == 'call_accepted') {
      _handleCallAccepted(data);
    }
  }

  void _showIncomingCall(Map<String, dynamic> data) {
    final callId = data['callId'] as String?;
    final callerName = data['callerName'] as String?;
    final callerAvatar = data['callerAvatar'] as String?;
    final token = data['token'] as String?;
    final roomName = data['roomName'] as String?;
    final livekitUrl = data['livekitUrl'] as String?;
    final callerId = data['callerId'] as String?;

    if (callId == null || callerName == null || token == null || roomName == null || livekitUrl == null || callerId == null) {
      return;
    }

    // Use NavigationService for global navigation (works in all app states)
    NavigationService().navigateToIncomingCall(
      callId: callId,
      callerId: callerId,
      callerName: callerName,
      token: token,
      roomName: roomName,
      livekitUrl: livekitUrl,
    );

    // Also send to BLoC for state management (for WebRTC compatibility)
    if (_context != null && _context!.mounted) {
      _context!.read<CallBloc>().add(IncomingCallReceivedEvent(
        callId: callId,
        callerName: callerName,
        callerAvatar: callerAvatar,
        token: token,
        roomName: roomName,
        livekitUrl: livekitUrl,
      ));
    }

    // Show CallKit incoming call UI on Android
    //_showCallKitIncoming(data);
  }

  Future<void> _showCallKitIncoming(Map<String, dynamic> data) async {
    final callId = data['callId'] as String;
    final callerName = data['callerName'] as String;
    final callerAvatar = data['callerAvatar'] as String?;

    await FlutterCallkitIncoming.showCallkitIncoming(
      fci_entities.CallKitParams(
        id: callId,
        nameCaller: callerName,
        appName: 'Gamatutor',
        avatar: callerAvatar ?? '',
        handle: callId,
        type: 0, // 0 = audio, 1 = video
        duration: 30000, // 30 seconds timeout
        extra: data,
        headers: <String, String>{},
        android: fci_entities.AndroidParams(
          isCustomNotification: true,
          isShowLogo: true,
          ringtonePath: 'system_ringtone_default',
          backgroundColor: '#007AFF',
          actionColor: '#FFFFFF',
          isShowCallID: false,
        ),
        ios: fci_entities.IOSParams(
          iconName: 'CallKitLogo',
          handleType: 'generic',
          supportsVideo: false,
          maximumCallGroups: 1,
          maximumCallsPerCallGroup: 1,
          audioSessionMode: 'default',
          audioSessionActive: true,
          audioSessionPreferredSampleRate: 44100.0,
          audioSessionPreferredIOBufferDuration: 0.005,
          supportsDTMF: false,
          supportsHolding: false,
          supportsGrouping: false,
          supportsUngrouping: false,
          ringtonePath: 'system_ringtone_default',
        ),
      ),
    );
  }

  void _handleCallAccepted(Map<String, dynamic> data) {
    final callId = data['callId'] as String?;
    final token = data['token'] as String?;
    final roomName = data['roomName'] as String?;
    final livekitUrl = data['livekitUrl'] as String?;

    if (callId == null || token == null || roomName == null || livekitUrl == null) {
      return;
    }

    // Send to BLoC for state management - caller receives this when callee accepts
    if (_context != null && _context!.mounted) {
      _context!.read<CallBloc>().add(CalleeAcceptedEvent(
        callId: callId,
        token: token,
        roomName: roomName,
        livekitUrl: livekitUrl,
      ));
    }
  }

  // Call this when user manually ends call to dismiss CallKit UI
  static Future<void> dismissIncomingCall(String callId) async {
    await FlutterCallkitIncoming.endCall(callId);
  }

  // Call this when call is active and user mutes/unmutes
  static Future<void> updateMuteState(String callId, bool isMuted) async {
    // Note: updateCallkitMuted might not be available in this version
    // await FlutterCallkitIncoming.updateCallkitMuted(isMuted);
  }

  // Call this to start ongoing call UI (when call is connected)
  static Future<void> startOngoingCall({
    required String callId,
    required String callerName,
    String? callerAvatar,
    required bool isMuted,
  }) async {
    await FlutterCallkitIncoming.showCallkitIncoming(
      fci_entities.CallKitParams(
        id: callId,
        nameCaller: callerName,
        appName: 'Gamatutor',
        avatar: callerAvatar ?? '',
        handle: callId,
        type: 0,
        duration: 0, // No timeout for ongoing call
        extra: {'isOngoing': true},
        headers: <String, String>{},
        android: fci_entities.AndroidParams(
          isCustomNotification: true,
          isShowLogo: true,
          backgroundColor: '#007AFF',
          actionColor: '#FFFFFF',
        ),
        ios: fci_entities.IOSParams(
          iconName: 'CallKitLogo',
          handleType: 'generic',
          supportsVideo: false,
          audioSessionMode: 'default',
          audioSessionActive: true,
        ),
      ),
    );
  }

  // Call this when ongoing call ends
  static Future<void> endOngoingCall(String callId) async {
    await FlutterCallkitIncoming.endCall(callId);
  }
}

// Widget to wrap app with incoming call handling
class IncomingCallProvider extends StatefulWidget {
  final Widget child;

  const IncomingCallProvider({
    super.key,
    required this.child,
  });

  @override
  State<IncomingCallProvider> createState() => _IncomingCallProviderState();
}

class _IncomingCallProviderState extends State<IncomingCallProvider> {
  @override
  void initState() {
    super.initState();
    // Initialize after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      IncomingCallHandler.instance.initialize(context);
    });
  }

  @override
  void dispose() {
    IncomingCallHandler.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}