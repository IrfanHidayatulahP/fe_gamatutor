import 'package:flutter/material.dart';
import 'package:gamatutor_kanban/features/calls/ui/livekit/active_call_screen.dart';
import 'package:gamatutor_kanban/features/calls/ui/livekit/incoming_call_screen.dart';

/// Global navigation service for handling incoming call navigation
/// across all app states (foreground, background, terminated)
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _isCallScreenOpen = false;
  String? _currentCallId;

  /// Set the global navigator key (called from main.dart after router is created)
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Get the current navigator key
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  /// Get the current navigator state
  NavigatorState? get navigator => _navigatorKey?.currentState;

  /// Get the current context
  BuildContext? get context => _navigatorKey?.currentContext;

  /// Check if a call screen is currently open
  bool get isCallScreenOpen => _isCallScreenOpen;

  /// Get the current call ID being handled
  String? get currentCallId => _currentCallId;

  /// Navigate to incoming call screen
  /// Returns true if navigation was successful, false if call screen is already open
  bool navigateToIncomingCall({
    required String callId,
    required String callerId,
    required String callerName,
    required String token,
    required String roomName,
    required String livekitUrl,
  }) {
    // Double-push prevention: if call screen already open for same call, ignore
    if (_isCallScreenOpen && _currentCallId == callId) {
      debugPrint('📞 Call screen already open for callId: $callId, ignoring duplicate');
      return false;
    }

    // If different call is open, reject the previous one first
    if (_isCallScreenOpen && _currentCallId != callId) {
      debugPrint('📞 Different call active ($_currentCallId), rejecting and opening new call: $callId');
      _rejectCurrentCall();
    }

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('⚠️ Navigator not available for incoming call navigation');
      return false;
    }

    _isCallScreenOpen = true;
    _currentCallId = callId;

    navigator.push(
      MaterialPageRoute(
        builder: (context) => _IncomingCallScreenWrapper(
          callId: callId,
          callerId: callerId,
          callerName: callerName,
          token: token,
          roomName: roomName,
          livekitUrl: livekitUrl,
          onCallScreenClosed: _onCallScreenClosed,
        ),
        fullscreenDialog: true,
      ),
    );

    debugPrint('📞 Navigated to incoming call screen for callId: $callId');
    return true;
  }

  /// Called when call screen is closed (accepted, rejected, or timeout)
  void _onCallScreenClosed(String? closedCallId) {
    if (_currentCallId == closedCallId || closedCallId == null) {
      _isCallScreenOpen = false;
      _currentCallId = null;
      debugPrint('📞 Call screen closed, isCallScreenOpen: $_isCallScreenOpen');
    }
  }

  /// Reject the currently active call
  void _rejectCurrentCall() {
    if (_currentCallId != null && context != null) {
      // The BLoC will handle the actual rejection when screen pops
      // This just clears the flag to allow new call
      _isCallScreenOpen = false;
      _currentCallId = null;
    }
  }

  /// Pop the incoming call screen (when user rejects or call times out)
  void popIncomingCall({String? callId}) {
    final navigator = _navigatorKey?.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
    _onCallScreenClosed(callId);
  }

  /// Navigate to active call screen (after accept)
  void navigateToActiveCall({
    required String callId,
    required String roomName,
    required String token,
    required String livekitUrl,
    required String otherParticipantName,
    required bool isInitiator,
  }) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('⚠️ Navigator not available for active call navigation');
      return;
    }

    // Replace the incoming call screen with active call screen
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (context) => _ActiveCallScreenWrapper(
          callId: callId,
          roomName: roomName,
          token: token,
          livekitUrl: livekitUrl,
          otherParticipantName: otherParticipantName,
          isInitiator: isInitiator,
        ),
        fullscreenDialog: true,
      ),
    );

    debugPrint('📞 Navigated to active call screen for callId: $callId');
  }

  /// Reset navigation state (call ended)
  void reset() {
    _isCallScreenOpen = false;
    _currentCallId = null;
    debugPrint('📞 Navigation service reset');
  }
}

/// Wrapper for IncomingCallScreen to handle lifecycle callbacks
class _IncomingCallScreenWrapper extends StatelessWidget {
  final String callId;
  final String callerId;
  final String callerName;
  final String token;
  final String roomName;
  final String livekitUrl;
  final Function(String?) onCallScreenClosed;

  const _IncomingCallScreenWrapper({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.token,
    required this.roomName,
    required this.livekitUrl,
    required this.onCallScreenClosed,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button - user must explicitly accept/decline
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Back button pressed - treat as reject
          debugPrint('📞 Back button pressed on incoming call, rejecting');
          // The IncomingCallScreen will handle the reject via its own logic
          // We don't pop here - let the screen handle it
        }
      },
      child: IncomingCallScreen(
        callId: callId,
        callerId: callerId,
        callerName: callerName,
        token: token,
        roomName: roomName,
        livekitUrl: livekitUrl,
        onClosed: onCallScreenClosed,
      ),
    );
  }
}

/// Wrapper for ActiveCallScreen to handle lifecycle callbacks
class _ActiveCallScreenWrapper extends StatelessWidget {
  final String callId;
  final String roomName;
  final String token;
  final String livekitUrl;
  final String otherParticipantName;
  final bool isInitiator;

  const _ActiveCallScreenWrapper({
    required this.callId,
    required this.roomName,
    required this.token,
    required this.livekitUrl,
    required this.otherParticipantName,
    required this.isInitiator,
  });

  @override
  Widget build(BuildContext context) {
    return LiveKitActiveCallScreen(
      callId: callId,
      roomName: roomName,
      token: token,
      livekitUrl: livekitUrl,
      otherParticipantName: otherParticipantName,
      isInitiator: isInitiator,
    );
  }
}