import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constants.dart';

/// Socket.io WebSocket client for real-time updates
class SocketClient {
  static IO.Socket? _socket;
  static bool _isConnected = false;

  static bool get isConnected => _isConnected;

  /// Initialize and connect socket
  static void init() {
    try {
      _socket = IO.io(
        AppConstants.wsBaseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket?.onConnect((_) {
        _isConnected = true;
        print('🔌 Socket connected to MineGuardian server');
      });

      _socket?.onDisconnect((_) {
        _isConnected = false;
        print('🔌 Socket disconnected');
      });

      _socket?.onConnectError((err) {
        _isConnected = false;
      });

      _socket?.connect();
    } catch (e) {
      print('Socket init error: $e');
    }
  }

  static void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  static void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  static void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
  }
}
