import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gamatutor_kanban/core/navigation/navigation_service.dart'; // For FocusManager

/// Global service for deferred/pending call navigation
/// Solves cold-start navigation issues by storing call payload until UI is ready
class CallNavigationService {
  /// Stores incoming call payload until Flutter UI is ready for navigation
  static Map<String, dynamic>? _pendingIncomingCall;

  static Map<String, dynamic>? pendingTerminatedCallPayload;

  /// Getter for pending call (read-only for external access)
  static Map<String, dynamic>? get pendingIncomingCall => _pendingIncomingCall;

  /// Checks if navigator is ready and executes pending navigation
  /// Should be called after first frame render (e.g., in BoardScreen.initState)
  /// Uses addPostFrameCallback to avoid RenderFollowerLayer errors when overlays are active
  static void checkAndNavigateToCall() {
    // Defer to next frame to avoid RenderFollowerLayer issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeNavigationIfReady();
    });
  }

  /// Internal method to execute navigation with safety checks
  static void _executeNavigationIfReady() {
    final navigator = NavigationService().navigator;

    if (_pendingIncomingCall != null && navigator != null && navigator.mounted) {
      // Check if context is safe (no active overlays/focus)
      final context = NavigationService().context;
      if (context != null && context.mounted) {
        // Dismiss keyboard/overlays before navigation to prevent RenderFollowerLayer
        FocusManager.instance.primaryFocus?.unfocus();

        final callData = Map<String, dynamic>.from(_pendingIncomingCall!);
        _pendingIncomingCall = null;

        debugPrint('📞 Executing deferred navigation for callId: ${callData['callId']}');

        NavigationService().navigateToIncomingCall(
          callId: callData['callId'] as String,
          callerId: callData['callerId'] as String,
          callerName: callData['callerName'] as String,
          token: callData['token'] as String,
          roomName: callData['roomName'] as String,
          livekitUrl: callData['livekitUrl'] as String,
        );
      } else {
        debugPrint('📞 Context not ready, will retry on next frame');
        // Re-queue for next frame
        WidgetsBinding.instance.addPostFrameCallback((_) => _executeNavigationIfReady());
      }
    } else if (_pendingIncomingCall != null) {
      debugPrint('📞 Pending call exists but navigator not ready: ${NavigationService().navigator?.mounted}');
    }
  }

  /// Stores incoming call payload for deferred navigation
  /// Called from CallKit Accept event handler
  static void setPendingIncomingCall(Map<String, dynamic> callData) {
    _pendingIncomingCall = Map<String, dynamic>.from(callData);
    debugPrint('📞 Stored pending incoming call: ${callData['callId']}');

    // Try immediate navigation if UI is already ready
    checkAndNavigateToCall();
  }

  /// Clears pending call (e.g., on timeout, decline, or manual clear)
  static void clearPendingCall() {
    if (_pendingIncomingCall != null) {
      debugPrint('📞 Cleared pending call: ${_pendingIncomingCall!['callId']}');
      _pendingIncomingCall = null;
    }
  }

  /// Checks if there's a pending call waiting for navigation
  static bool get hasPendingCall => _pendingIncomingCall != null;
}