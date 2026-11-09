import 'dart:async';
import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../utils/constants.dart';
import '../storage/token_storage.dart';

typedef WebSocketMessageHandler = void Function(Map<String, dynamic> message);
typedef WebSocketCallback = void Function(Map<String, dynamic> response);

class WebSocketManager {
  IO.Socket? _socket;
  final TokenStorage _tokenStorage;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final Map<String, List<WebSocketMessageHandler>> _eventHandlers = {};
  final Map<String, WebSocketCallback> _pendingCallbacks = {};
  int _callbackId = 0;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  bool _disposed = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  WebSocketManager(this._tokenStorage);

  Future<void> connect() async {
    if (_socket != null || _isConnecting || _disposed) return;

    _isConnecting = true;
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      _isConnecting = false;
      return;
    }

    try {
      _socket = IO.io(ApiConstants.wsBaseUrl, IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .setQuery({'token': token})
          .enableAutoConnect()
          .build());

      _socket!.onConnect((_) {
        _isConnecting = false;
        _reconnectAttempts = 0;
      });

      _socket!.onDisconnect((_) {
        _isConnecting = false;
        if (!_disposed) {
          _scheduleReconnect();
        }
      });

      _socket!.onError((error) {
        _isConnecting = false;
        if (!_disposed) {
          _scheduleReconnect();
        }
      });

      // Listen to all events using onAny
      _socket!.onAny((event, data) {
        final message = data as Map<String, dynamic>;
        message['event'] = event;
        _messageController.add(message);
        _handleEvent(message);
      });

    } catch (e) {
      _isConnecting = false;
      _scheduleReconnect();
    }
  }

  void _handleEvent(Map<String, dynamic> message) {
    final eventType = message['event'] ?? message['type'];

    // Handle callback responses (success/error responses to emitted events)
    if (message['id'] != null && _pendingCallbacks.containsKey(message['id'])) {
      final callback = _pendingCallbacks.remove(message['id']);
      callback?.call(message);
    }

    // Handle regular event handlers
    if (eventType != null && _eventHandlers.containsKey(eventType)) {
      for (final handler in _eventHandlers[eventType]!) {
        handler(message);
      }
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectAttempts++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * _reconnectAttempts, () {
      if (!_disposed) {
        connect();
      }
    });
  }

  void send(Map<String, dynamic> message) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('message', [message]);
    }
  }

  void on(String eventType, WebSocketMessageHandler handler) {
    _eventHandlers.putIfAbsent(eventType, () => []).add(handler);
  }

  void off(String eventType, [WebSocketMessageHandler? handler]) {
    if (handler != null) {
      _eventHandlers[eventType]?.remove(handler);
    } else {
      _eventHandlers.remove(eventType);
    }
  }

  void emit(String eventType, Map<String, dynamic> data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(eventType, data);
    }
  }

  /// Emit an event and wait for a response with the same ID
  Future<Map<String, dynamic>> emitWithCallback(String eventType, Map<String, dynamic> data) {
    final completer = Completer<Map<String, dynamic>>();
    final callbackId = 'cb_${_callbackId++}';
    _pendingCallbacks[callbackId] = completer.complete;

    send({'event': eventType, 'id': callbackId, ...data});

    // Timeout after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (_pendingCallbacks.containsKey(callbackId)) {
        _pendingCallbacks.remove(callbackId);
        completer.completeError(Exception('Timeout waiting for response'));
      }
    });

    return completer.future;
  }

  bool get isConnected => _socket?.connected ?? false;

  Future<void> disconnect() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket = null;
    _isConnecting = false;
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _messageController.close();
    _eventHandlers.clear();
  }
}