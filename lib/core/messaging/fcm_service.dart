import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart'; // For FocusManager
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart' as fci_entities;
import 'package:go_router/go_router.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';
import '../navigation/navigation_service.dart';

// Voice-only app: helper to detect incoming call from various payload types
bool _isIncomingCallData(Map<String, dynamic> data) {
  final type = data['type'];
  final hasCallFields = data['callId'] != null && data['callerId'] != null &&
                        data['callerName'] != null && data['token'] != null &&
                        data['roomName'] != null && data['livekitUrl'] != null;
  return (type == 'call_incoming' || type == 'incoming_call' ||
          type == 'video' || type == 'audio') && hasCallFields;
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Background message: ${message.messageId}');
  debugPrint('🔔 Data: ${message.data}');

  // Trigger CallKit for incoming calls in background/terminated
  if (_isIncomingCallData(message.data)) {
    await _showCallKitIncomingFromBackground(message);
    return; // Don't show regular notification for calls
  }

  debugPrint('🔔 Notification: ${message.notification?.title} - ${message.notification?.body}');
}

/// Show native CallKit UI from background isolate for incoming calls
@pragma('vm:entry-point')
Future<void> _showCallKitIncomingFromBackground(RemoteMessage message) async {
  final data = message.data;

  // Only for incoming call types (voice-only app)
  if (!_isIncomingCallData(data)) {
    return;
  }

  final callId = data['callId'];
  final callerName = data['callerName'];
  final callerAvatar = data['callerAvatar'];

  if (callId == null || callerName == null) return;

  debugPrint('📞 Showing CallKit UI from background for callId: $callId');

  // Use flutter_callkit_incoming to show native CallKit UI
  try {
    await FlutterCallkitIncoming.showCallkitIncoming(
      fci_entities.CallKitParams(
        id: callId,
        nameCaller: callerName,
        appName: 'Gamatutor',
        avatar: callerAvatar ?? '',
        handle: callId,
        type: 0, // 0 = audio (voice-only app)
        duration: 30000,
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
          supportsVideo: false, // Voice-only app
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
  } catch (e) {
    debugPrint('❌ Failed to show CallKit from background: $e');
  }
}

/// Local notification tap handler (must be top-level function for background isolate)
@pragma('vm:entry-point')
void _onNotificationTappedGlobal(NotificationResponse response) {
  debugPrint('🔔 Local notification tapped (global): ${response.payload}');

  if (response.payload != null) {
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      // Add 500ms delay for Flutter UI to be ready
      Future.delayed(const Duration(milliseconds: 500), () {
        FCMNavigationHandler.handleFromBackground(data.map((k, v) => MapEntry(k, v.toString())));
      });
    } catch (e) {
      debugPrint('❌ Failed to parse notification payload: $e');
    }
  }
}

class FCMService {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final TokenStorage _tokenStorage;
  final ApiClient _apiClient;

  FirebaseMessaging? _messaging;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<String>? _onTokenRegisteredSubscription;

  bool _initialized = false;
  String? _currentToken;

  FCMService(this._tokenStorage, this._apiClient);

  FirebaseMessaging get _messagingInstance {
    _messaging ??= FirebaseMessaging.instance;
    return _messaging!;
  }

  /// Initialize FCM and local notifications
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Firebase - on web, this requires options
      if (kIsWeb) {
        debugPrint('🌐 Web platform detected - skipping Firebase.initializeApp() (requires Firebase options)');
        // On web, Firebase must be initialized with options in main.dart or index.html
        // If not configured, we gracefully skip FCM on web
        _initialized = true;
        debugPrint('⚠️ FCM Service initialized in web-compatibility mode (limited functionality)');
        return;
      }

      // Mobile platforms (Android/iOS) - initialize normally
      await Firebase.initializeApp();

      // Setup local notifications
      await _initLocalNotifications();

      // Request permissions (iOS)
      await _requestPermissions();

      // Register for FCM token (replaces deprecated getToken)
      await _messagingInstance.register();

      // Listen for token registration (replaces deprecated onTokenRefresh)
      _onTokenRegisteredSubscription = _messagingInstance.onRegistered.listen(_onTokenRefresh);

      // Handle foreground messages
      _onMessageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages that user tapped to open app
      _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle terminated app state (cold start)
      final initialMessage = await _messagingInstance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      // Set background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      _initialized = true;
      debugPrint('✅ FCM Service initialized');
    } catch (e) {
      debugPrint('❌ FCM initialization failed: $e');
      rethrow;
    }
  }

  /// Register current FCM token with backend (call after login)
  Future<void> registerTokenIfLoggedIn() async {
    if (!_initialized) return;
    try {
      final hasToken = await _tokenStorage.hasValidToken();
      if (!hasToken) return;

      if (_currentToken != null) {
        await _registerTokenWithBackend(_currentToken!);
      } else {
        // Re-register to trigger onRegistered stream
        await _messagingInstance.register();
      }
    } catch (e) {
      debugPrint('❌ Failed to register FCM token after login: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTappedGlobal,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTappedGlobal,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const channel = AndroidNotificationChannel(
      'gamatutor_default',
      'Gamatutor Notifications',
      description: 'General notifications for Gamatutor app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const callChannel = AndroidNotificationChannel(
      'gamatutor_calls',
      'Incoming Calls',
      description: 'Incoming voice/video call notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(callChannel);
  }

  Future<void> _requestPermissions() async {
    final settings = await _messagingInstance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('📱 Notification permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Also request exact alarm permission for Android 14+ if needed
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> _onTokenRefresh(String newToken) async {
    debugPrint('🔄 FCM Token refreshed: $newToken');
    _currentToken = newToken;

    await _registerTokenWithBackend(newToken);
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final hasToken = await _tokenStorage.hasValidToken();
      if (!hasToken) return;

      // Map platform to accepted values: android, ios, web
      final platform = switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        TargetPlatform.macOS || TargetPlatform.windows || TargetPlatform.linux || TargetPlatform.fuchsia => 'web',
      };

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/users/fcm-token',
        data: {'fcmToken': token, 'platform': platform},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ FCM token registered with backend (platform: $platform)');
      }
    } catch (e) {
      debugPrint('❌ Failed to register FCM token: $e');
    }
  }

  Future<void> unregisterToken() async {
    try {
      final hasToken = await _tokenStorage.hasValidToken();
      if (!hasToken) return;

      await _apiClient.delete<Map<String, dynamic>>('/users/fcm-token');
      debugPrint('✅ FCM token unregistered from backend');
    } catch (e) {
      debugPrint('❌ Failed to unregister FCM token: $e');
    }
  }

  // Voice-only app: helper to detect incoming call from various payload types
  bool _isIncomingCall(Map<String, dynamic> data) {
    final type = data['type'];
    final hasCallFields = data['callId'] != null && data['callerId'] != null &&
                          data['callerName'] != null && data['token'] != null &&
                          data['roomName'] != null && data['livekitUrl'] != null;
    return (type == 'call_incoming' || type == 'incoming_call' ||
            type == 'video' || type == 'audio') && hasCallFields;
  }

  // void _handleForegroundMessage(RemoteMessage message) {
  //   debugPrint('🔔 Foreground message: ${message.messageId}');
  //   debugPrint('🔔 Data: ${message.data}');

  //   // Handle incoming call via IncomingCallHandler
  //   if (_isIncomingCall(message.data)) {
  //     // The IncomingCallHandler will handle this via its own listener
  //     // We still show local notification as fallback
  //   }

  //   // Show local notification
  //   _showLocalNotification(message);

  //   // Also emit to NotificationBloc for in-app toast (if needed)
  //   // This avoids duplicate notifications when app is in foreground
  // }

    void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message: ${message.messageId}');
    debugPrint('🔔 Data: ${message.data}');

    // Incoming call notifications are handled exclusively by IncomingCallHandler
    // (foreground) and _firebaseMessagingBackgroundHandler (background).
    // Skip here to avoid duplicate local notification.
    if (_isIncomingCall(message.data)) {
      debugPrint('📞 FCMService: skipping incoming call (handled by IncomingCallHandler)');
      return;
    }

    _showLocalNotification(message);
  }

    void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('🔔 Message opened app: ${message.messageId}');
    debugPrint('🔔 Data: ${message.data}');

    // Incoming calls handled by IncomingCallHandler / CallKit, not by
    // notification tap navigation.
    if (_isIncomingCall(message.data)) {
      debugPrint('📞 FCMService: skipping incoming call navigation');
      return;
    }

    _navigateFromNotification(message.data.map((k, v) => MapEntry(k, v.toString())));
  }

  
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    // Determine channel based on type
    String channelId = 'gamatutor_default';
    if (data['type'] == 'call_incoming' || data['type'] == 'group_call_invite') {
      channelId = 'gamatutor_calls';
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == 'gamatutor_calls' ? 'Incoming Calls' : 'Gamatutor Notifications',
      channelDescription: channelId == 'gamatutor_calls'
          ? 'Incoming voice/video call notifications'
          : 'General notifications for Gamatutor app',
      importance: channelId == 'gamatutor_calls' ? Importance.max : Importance.high,
      priority: channelId == 'gamatutor_calls' ? Priority.max : Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: channelId == 'gamatutor_calls',
      category: channelId == 'gamatutor_calls' ? AndroidNotificationCategory.call : AndroidNotificationCategory.message,
      icon: '@mipmap/ic_launcher',
      largeIcon: data['imageUrl'] != null ? ByteArrayAndroidBitmap(await _downloadImage(data['imageUrl']!) ?? Uint8List(0)) : null,
      styleInformation: BigTextStyleInformation(
        notification?.body ?? data['message'] ?? '',
        htmlFormatBigText: true,
        contentTitle: notification?.title ?? data['title'] ?? 'Gamatutor',
        htmlFormatContentTitle: true,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Encode data as JSON payload
    final payload = jsonEncode(data);

    await _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title: notification?.title ?? data['title'],
      body: notification?.body ?? data['message'],
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final response = await _apiClient.dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? []);
    } catch (e) {
      debugPrint('❌ Failed to download notification image: $e');
      return null;
    }
  }

  void _navigateFromNotification(Map<String, String> data) {
    final type = data['type'];
    if (type == null) return;
    final triggerAction = data['triggerAction'];
    final triggerUserId = data['triggerUserId'];
    final collabId = data['collabId'];
    final groupCallId = data['groupCallId'];
    final callId = data['callId'];
    final callerId = data['callerId'];
    final callerName = data['callerName'];
    final token = data['token'];
    final roomName = data['roomName'];
    final livekitUrl = data['livekitUrl'];

    // if (type == null) return;

    final hasCallFields = callId != null && callerId != null && callerName != null &&
                          token != null && roomName != null && livekitUrl != null;
    final isCallType = type == 'call_incoming' || type == 'incoming_call' ||
                       type == 'video' || type == 'audio';

    // Handle incoming call - use NavigationService for global navigation
    // Accept all call type variants (call_incoming, incoming_call, video, audio) as voice calls
    if (hasCallFields && (isCallType || type == 'call' || type == 'voice_call')) {
      NavigationService().navigateToIncomingCall(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        token: token,
        roomName: roomName,
        livekitUrl: livekitUrl,
      );
      return;
    }

    // Use navigator key or context from main.dart for other types
    // For now, we'll use a global navigator approach
    // This will be connected in main.dart
    FCMNavigationHandler.handle(type, {
      'triggerAction': triggerAction,
      'triggerUserId': triggerUserId,
      'collabId': collabId,
      'groupCallId': groupCallId,
    });
  }

  void dispose() {
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _onTokenRegisteredSubscription?.cancel();
    _initialized = false;
  }
}

/// Global navigation handler for FCM notifications
class FCMNavigationHandler {
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  static void handle(String type, Map<String, String?> params) {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('⚠️ No navigator context for FCM navigation');
      return;
    }

    _navigate(context, type, params);
  }

  /// Handle navigation from notification tap (foreground or background)
  /// Executes immediately if navigator is available (foreground), queues if not (background/terminated)
  static void handleFromBackground(Map<String, String> data) {
    final type = data['type'];
    if (type == null) return;

    debugPrint('🔔 Notification tap received: $type, data: $data');

    // Try immediate execution if navigator is available (app in foreground)
    final navigator = _navigatorKey?.currentState;
    final context = _navigatorKey?.currentContext;

    if (navigator != null && context != null && navigator.mounted && context.mounted) {
      debugPrint('📞 Executing navigation immediately (foreground) - navigator ready');
      // Dismiss keyboard/overlays first to prevent RenderFollowerLayer
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _navigate(context, type, Map<String, String?>.from(data));
        } else {
          debugPrint('📞 Context not mounted in post-frame, queuing for retry');
          _pendingNavigation = {
            'type': type,
            'params': data,
          };
        }
      });
    } else {
      // App not ready yet (background/terminated) - queue for later
      debugPrint('📞 Queuing navigation for later execution (navigator: ${navigator?.mounted}, context: ${context?.mounted})');
      _pendingNavigation = {
        'type': type,
        'params': data,
      };
    }
  }

  static Map<String, dynamic>? _pendingNavigation;

  static void executePendingNavigation(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey; // Update reference
    if (_pendingNavigation != null && navigatorKey.currentContext != null && navigatorKey.currentState != null) {
      final pending = _pendingNavigation!;
      debugPrint('📞 Executing queued navigation: ${pending['type']}');
      final context = navigatorKey.currentContext!;
      FocusManager.instance.primaryFocus?.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && navigatorKey.currentState?.mounted == true) {
          _navigate(context, pending['type'],
              Map<String, String?>.from(pending['params']));
          _pendingNavigation = null;
        } else {
          debugPrint('📞 Context/navigator not ready in executePendingNavigation, keeping queued');
        }
      });
    } else if (_pendingNavigation != null) {
      debugPrint('📞 Pending navigation exists but navigator not ready: state=${navigatorKey.currentState?.mounted}, context=${navigatorKey.currentContext?.mounted}');
    }
  }

  static void _navigate(BuildContext context, String type, Map<String, String?> params) {
    // First check if this is an incoming call notification (has call fields)
    // This handles both 'call_incoming' type AND 'video'/'audio' types from backend
    // Also handles case where type might be missing or different but call fields are present
    final callId = params['callId'];
    final callerId = params['callerId'];
    final callerName = params['callerName'];
    final token = params['token'];
    final roomName = params['roomName'];
    final livekitUrl = params['livekitUrl'];

    final hasCallFields = callId != null && callerId != null && callerName != null &&
                          token != null && roomName != null && livekitUrl != null;
    final isCallType = type == 'call_incoming' || type == 'incoming_call' ||
                       type == 'video' || type == 'audio';

    // If it has all call fields, treat as incoming call regardless of type field
    // This handles edge cases where type might not match exactly
    if (hasCallFields && (isCallType || type == 'call' || type == 'voice_call')) {
      debugPrint('📞 FCMNavigationHandler: Detected incoming call, navigating to IncomingCallScreen');
      debugPrint('📞   callId: $callId, callerName: $callerName, type: $type');
      // Use NavigationService for proper call screen navigation (handles CallKit, double-push prevention, etc.)
      NavigationService().navigateToIncomingCall(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        token: token,
        roomName: roomName,
        livekitUrl: livekitUrl,
      );
      return;
    }

    debugPrint('📞 FCMNavigationHandler: Not a call notification, type=$type, hasCallFields=$hasCallFields');
    debugPrint('📞   callId=$callId, callerId=$callerId, callerName=$callerName, token=$token, roomName=$roomName, livekitUrl=$livekitUrl');

    // Handle call_missed separately (navigate to history)
    if (type == 'call_missed') {
      GoRouter.of(context).push('/call-history');
      return;
    }

    // All other notification types - existing logic
    switch (type) {
      case 'friend_request_received':
      case 'friend_request_accepted':
      case 'friend_request_rejected':
        GoRouter.of(context).push('/pending-requests');
        break;
      case 'group_call_invite':
      case 'group_call_starting':
        if (params['groupCallId'] != null) {
          GoRouter.of(context).push('/group-call/${params['groupCallId']}');
        }
        break;
      case 'collaboration_invite':
        GoRouter.of(context).push('/collaboration-invites');
        break;
      case 'collab_new_message':
      case 'mention_in_collab':
        if (params['collabId'] != null) {
          GoRouter.of(context).push('/collab-chat/${params['collabId']}');
        }
        break;
      case 'card_updated_by_collaborator':
        if (params['triggerAction'] != null) {
          GoRouter.of(context).push('/board');
        }
        break;
      case 'smart_reminder':
      case 'encouragement':
        GoRouter.of(context).push('/board');
        break;
      case 'focus_request_received':
        // Arahkan ke layar notifikasi agar user bisa tap dan melihat dialog
        GoRouter.of(context).push('/notifications');
        break;
      default:
        GoRouter.of(context).push('/notifications');
    }
  }
}