import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../utils/constants.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _userId;
  
  // Callbacks
  Function(Map<String, dynamic>)? onEmergencyAlert;
  Function(bool)? onConnectionChanged;

  bool get isConnected => _isConnected;

  void connect(String userId) {
    _userId = userId;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(AppConstants.wsUrl));
      _isConnected = true;
      onConnectionChanged?.call(true);

      // Authenticate
      _sendMessage({
        'type': 'auth',
        'userId': userId,
      });

      // Listen to messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          _isConnected = false;
          onConnectionChanged?.call(false);
        },
        onDone: () {
          _isConnected = false;
          onConnectionChanged?.call(false);
        },
      );
    } catch (e) {
      _isConnected = false;
      onConnectionChanged?.call(false);
    }
  }

  void disconnect() {
    _channel?.sink.close(status.goingAway);
    _isConnected = false;
    _userId = null;
    onConnectionChanged?.call(false);
  }

  void sendEmergencyAlert(String message, double confidence) {
    if (_isConnected && _userId != null) {
      _sendMessage({
        'type': 'emergency_detected',
        'userId': _userId,
        'message': message,
        'confidence': confidence,
      });
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(message.toString());
    }
  }

  void _handleMessage(dynamic message) {
    try {
      // Parse the message and handle different types
      final data = message as Map<String, dynamic>;
      
      if (data['type'] == 'emergency_alert') {
        onEmergencyAlert?.call(data);
      }
    } catch (e) {
      // Handle parsing errors
    }
  }
}